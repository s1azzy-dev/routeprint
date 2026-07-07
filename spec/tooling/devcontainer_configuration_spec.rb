# frozen_string_literal: true

require "json"
require "pathname"
require "yaml"

class DevcontainerConfiguration
end

RSpec.describe DevcontainerConfiguration do
  let(:root) { Pathname(__dir__).join("../..").expand_path }
  let(:devcontainer_config) { JSON.parse(root.join(".devcontainer/devcontainer.json").read) }
  let(:devcontainer_compose) { YAML.safe_load(root.join(".devcontainer/docker-compose.yml").read) }

  it "runs from the Rails compose service" do
    expect(devcontainer_config).to include(
      "service" => "web",
      "workspaceFolder" => "/app",
      "shutdownAction" => "stopCompose",
    )
    expect(devcontainer_config.fetch("dockerComposeFile")).to eq(
      [ "../docker-compose.yml", "docker-compose.yml" ],
    )
    expect(devcontainer_config.fetch("runServices")).to contain_exactly("db", "jobs")
  end

  it "keeps Ruby and Node versions aligned across container tooling" do
    dockerfiles = %w[Dockerfile Dockerfile.dev Dockerfile.devcontainer].map { |path| root.join(path).read }

    expect(root.join(".ruby-version").read.strip).to eq("ruby-4.0.5")
    expect(root.join(".tool-versions").read).to include("ruby 4.0.5", "nodejs 24.18.0")
    expect(dockerfiles).to all(include("ARG RUBY_VERSION=4.0.5"))
    expect(dockerfiles).to all(include("ARG RUBYGEMS_VERSION=4.0.15"))
    expect(devcontainer_compose.dig("services", "web", "build", "dockerfile")).to eq("Dockerfile.devcontainer")
  end

  it "keeps project Codex config safe for local work" do
    codex_config = root.join(".codex/config.toml").read

    expect(codex_config).to include('approval_policy = "on-request"')
    expect(codex_config).to include('sandbox_mode = "workspace-write"')
    expect(codex_config).not_to match(/api[_-]?key|token|secret|password/i)
  end
end
