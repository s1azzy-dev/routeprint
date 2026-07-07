# frozen_string_literal: true

require "json"
require "pathname"
require "yaml"

class OpenSpecConfiguration
end

RSpec.describe OpenSpecConfiguration do
  let(:root) { Pathname(__dir__).join("../..").expand_path }
  let(:config) { YAML.safe_load(root.join("openspec/config.yaml").read) }

  it "pins Node and OpenSpec versions" do
    package = JSON.parse(root.join("package.json").read)

    expect(root.join(".tool-versions").read).to include("nodejs 24.18.0")
    expect(package.dig("engines", "node")).to eq("24.18.0")
    expect(package.dig("devDependencies", "@fission-ai/openspec")).to eq("1.5.0")
  end

  it "layers feature specifications over the repository harness" do
    expect(config.fetch("schema")).to eq("spec-driven")
    expect(config.fetch("context")).to include(
      "AGENTS.md",
      "docs/DEVELOPMENT.md",
      "docs/CONTEXT_MAP.md",
      "docs/FOUNDATIONS.md",
      "docs/QUALITY_SECURITY.md",
      "docs/frontend/DESIGN_GUIDE.md",
      "docs/TODO.md",
    )
    expect(config.fetch("rules").keys).to contain_exactly("proposal", "specs", "design", "tasks")
  end

  it "keeps the bootstrap capability baseline present" do
    spec = root.join("openspec/specs/bootstrap-foundation/spec.md").read

    expect(spec).to include("## Purpose", "## Requirements")
    expect(spec).to include("Routeprint SHALL")
  end

  it "integrates OpenSpec with Make and CI" do
    makefile = root.join("Makefile").read
    workflow = root.join(".github/workflows/ci.yml").read

    expect(makefile).to include("openspec-install:", "openspec-validate:")
    expect(makefile).to include("bin/openspec validate --all --strict")
    expect(workflow).to include("make openspec-validate")
  end
end
