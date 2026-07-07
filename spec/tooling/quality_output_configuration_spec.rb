# frozen_string_literal: true

require "json"
require "pathname"

class QualityOutputConfiguration
end

RSpec.describe QualityOutputConfiguration do
  let(:root) { Pathname(__dir__).join("../..").expand_path }

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
    expect(makefile).to include("rtk rubocop -A --format simple --config /app/.rubocop.yml")
  end
end
