# frozen_string_literal: true

require "json"
require "pathname"

class QualityOutputConfiguration
end

RSpec.describe QualityOutputConfiguration do
  let(:root) { Pathname(__dir__).join("../..").expand_path }
  let(:ci_workflow) { root.join(".github/workflows/ci.yml").read }

  it "uses a minimal RSpec formatter by default" do
    rspec_options = root.join(".rspec").read
    formatter = root.join("spec/support/minimal_rspec_formatter.rb").read

    expect(rspec_options).to include("--require ./spec/support/minimal_rspec_formatter")
    expect(rspec_options).to include("--format MinimalRspecFormatter")
    expect(rspec_options).not_to include("--format documentation")
    expect(formatter).to include("RSpec::Core::Formatters.register")
    expect(formatter).to include("dump_summary")
  end

  it "uses compact frontend quality command defaults" do
    scripts = JSON.parse(root.join("package.json").read).fetch("scripts")
    vite_config = root.join("vite.config.ts").read

    expect(scripts).to include(
      "frontend:format" => 'prettier --check --log-level warn "app/frontend/**/*.{ts,tsx,css}" vite.config.ts eslint.config.mjs package.json tsconfig.json components.json',
      "frontend:lint" => "eslint . --quiet",
      "frontend:test" => "vitest run --coverage --reporter=minimal --passWithNoTests",
      "frontend:typecheck" => "tsc --noEmit --pretty false"
    )
    expect(vite_config).to include('reporter: ["text-summary", "html"]')
  end

  it "uses a compact RuboCop formatter unless a caller requests one" do
    rubocop = root.join("bin/rubocop").read

    expect(rubocop).to include('ARGV.unshift("--format", "simple") unless format_requested')
    expect(rubocop).to include('arg == "-f"')
    expect(rubocop).to include('arg == "--format"')
    expect(rubocop).to include('arg.start_with?("--format=")')
  end

  it "keeps agent feedback commands compact without relying only on RTK" do
    makefile = root.join("Makefile").read

    expect(makefile).to include("rtk prettier $(RTK_FRONTEND_FORMAT_ARGS)")
    expect(makefile).to include("rtk eslint . --quiet")
    expect(makefile).to include("rtk tsc --noEmit --pretty false")
    expect(makefile).to include("rtk vitest run --coverage --reporter=minimal --passWithNoTests")
    expect(makefile).to include("rtk rubocop --format simple --config /app/.rubocop.yml")
  end

  it "keeps RuboCop checking separate from explicit autocorrection" do
    makefile = root.join("Makefile").read

    expect(makefile).to include("rubocop-check:")
    expect(makefile).to include("bin/rubocop --format simple --config /app/.rubocop.yml")
    expect(makefile).to include("rubocop-fix:")
    expect(makefile).to include("bin/rubocop -A --format simple --config /app/.rubocop.yml")
    expect(makefile).to include("agent-rubocop-fix:")

    verification_targets = makefile.scan(
      /^(?:verify|verify-fast|agent-verify-fast):.*?(?=^[^\t ]|\z)/m
    ).join

    expect(verification_targets).not_to include("-A")
  end

  it "keeps frontend formatting checks separate from explicit fixes" do
    makefile = root.join("Makefile").read

    expect(makefile).to include(
      "agent-frontend-format:",
      "rtk prettier $(RTK_FRONTEND_FORMAT_ARGS)",
      "agent-frontend-format-fix:",
      "rtk prettier --write --log-level warn $(FILES)"
    )
  end

  it "keeps the CI RuboCop check non-mutating" do
    expect(ci_workflow).to include("run: bin/rubocop -f github")
    expect(ci_workflow).not_to include("bin/rubocop -A")
  end

  it "centralizes the Ruby and frontend verification gates" do
    makefile = root.join("Makefile").read

    expect(makefile).to include(
      "frontend-check: frontend-format frontend-lint frontend-typecheck frontend-test frontend-build",
      "ruby-test:",
      "agent-ruby-test:",
      "verify-fast: frontend-install frontend-check rubocop-check ruby-test"
    )
  end
end
