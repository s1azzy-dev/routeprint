# frozen_string_literal: true

require "json"
require "pathname"
require "yaml"

class OpenSpecConfiguration
end

RSpec.describe OpenSpecConfiguration do
  let(:root) { Pathname(__dir__).join("../..").expand_path }
  let(:config) { YAML.safe_load(root.join("openspec/config.yaml").read) }
  let(:tool_config) { JSON.parse(root.join("config/openspec/config.json").read) }
  let(:dependabot) { YAML.safe_load(root.join(".github/dependabot.yml").read) }
  let(:todo) { root.join("docs/TODO.md").read }

  it "pins Node and OpenSpec versions" do
    package = JSON.parse(root.join("package.json").read)

    expect(root.join(".tool-versions").read).to include("nodejs 24.18.0")
    expect(package.dig("engines", "node")).to eq("24.18.0")
    expect(package.dig("devDependencies", "@fission-ai/openspec")).to eq("1.6.0")
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

  it "tracks the OpenSpec command delivery profile" do
    expect(tool_config.fetch("profile")).to eq("custom")
    expect(tool_config.fetch("delivery")).to eq("commands")
    expect(tool_config.fetch("workflows")).to contain_exactly(
      "propose",
      "explore",
      "apply",
      "sync",
      "archive"
    )
  end

  it "does not leave archived change ids in the deferred work queue" do
    archived_change_refs = root.join("openspec/changes/archive").children.filter_map do |path|
      next unless path.directory?

      archived_id = path.basename.to_s
      [ archived_id, archived_id.sub(/\A\d{4}-\d{2}-\d{2}-/, "") ]
    end.flatten

    expect(todo).not_to include(*archived_change_refs)
  end

  it "groups weekly npm minor and patch updates while leaving majors separate" do
    npm_update = dependabot.fetch("updates").find { |update| update.fetch("package-ecosystem") == "npm" }

    expect(npm_update).to include(
      "directory" => "/",
      "schedule" => { "interval" => "weekly" },
      "open-pull-requests-limit" => 10,
    )
    expect(npm_update.dig("groups", "frontend-minor-patch", "update-types")).to eq(%w[minor patch])
  end
end
