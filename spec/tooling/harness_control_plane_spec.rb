# frozen_string_literal: true

require "pathname"

class HarnessControlPlane
end

RSpec.describe HarnessControlPlane do
  let(:root) { Pathname(__dir__).join("../..").expand_path }
  let(:development) { root.join("docs/DEVELOPMENT.md").read }
  let(:foundations) { root.join("docs/FOUNDATIONS.md").read }
  let(:context_map) { root.join("docs/CONTEXT_MAP.md").read }
  let(:makefile) { root.join("Makefile").read }
  let(:codex_rules) { root.join(".codex/rules/rspec.rules").read }
  let(:readme) { root.join("README.md").read }
  let(:yabi_skill) { root.join(".agents/skills/routeprint-yabi-interactor/SKILL.md").read }

  it "keeps the SDD gate, command routing, and completion proof explicit" do
    expect(development).to include(
      "Every repository task starts with SDD classification",
      "Choose the command environment before the first executable command",
      "Do not run raw `bundle`,",
      "Run the SDD gate for every repository task"
    )
    expect(development).to include(
      "Tool/check fails for unrelated reason",
      "Context compacts mid-task",
      "When work is complete, summarize"
    )
  end

  it "routes core workflows through project-local skills" do
    expect(context_map).to include("## Project Skill Routing")
    expect(context_map).to include(
      "$routeprint-sdd-intake-gate",
      "$routeprint-spec-driven-change",
      "$routeprint-workspace-state"
    )
    expect(context_map).to include(
      "Use project-local skills before broad global skills",
      "Load only the routed skill plus the rows named by this map"
    )
  end

  it "routes domain workflows through project-local skills" do
    expect(context_map).to include(
      "$routeprint-authz-security-flow",
      "$routeprint-postgis-map-query",
      "$routeprint-yabi-interactor"
    )
  end

  it "keeps OpenSpec skills compact and Routeprint-wrapped" do
    skill_paths = root.join(".agents/skills").glob("openspec-*/SKILL.md")

    expect(skill_paths).not_to be_empty

    skill_paths.each do |path|
      content = path.read
      line_count = content.lines.count

      expect(line_count).to be <= 90
      expect(content).to include("bin/openspec")
      expect(content).to include("never use bare `openspec`")
      expect(content).to include("read\n  `references/")
    end
  end

  it "keeps generated OpenSpec examples out of the hot skill path" do
    root.join(".agents/skills").glob("openspec-*/SKILL.md").each do |path|
      content = path.read

      expect(content).not_to include("AskUserQuestion tool")
      expect(content).not_to include("Use ASCII diagrams liberally")
    end
  end

  it "keeps detailed OpenSpec quality guidance lazy-loaded" do
    references = root.join(".agents/skills").glob("openspec-*/references/*.md")
    reference_text = references.map(&:read).join("\n")

    expect(references.size).to eq(6)
    expect(reference_text).to include(
      "resolvedOutputPath",
      "Idempotency: no second-pass changes",
      "strict OpenSpec validation",
      "store list --json",
      "--store <id>"
    )
  end

  it "provides a compact workspace snapshot target" do
    expect(makefile).to include(
      "agent-state: agent-host-state",
      "agent-host-state:",
      "git status -sb --untracked-files=all",
      "git diff --name-status"
    )
    expect(development).to include("make agent-state")
  end

  it "defines the explicit fail-fast interactor style in project docs" do
    expect(foundations).to include("explicit, fail-fast pipelines")
    expect(development).to include(
      "## Interactor Execution Loop",
      "Only `call` reads from `input`",
      "pipeline step into another interactor"
    )
  end

  it "keeps the canonical interactor rules in the routed skill" do
    expect(yabi_skill).to include(
      "`call` is normally an orchestrator",
      "call another interactor by constant",
      "Do not add dummy `input` or an empty contract",
      "Document every interactor class with concise YARD",
      "Rescue only where the exception can be handled meaningfully"
    )
  end

  it "keeps archived feature completion synchronized across project documents" do
    expect(development).to include(
      "## Completion Synchronization Checklist",
      "update `CHANGES.md`",
      "Current Runtime Foundation",
      "remove the corresponding item from `docs/TODO.md`"
    )
    expect(readme).to include(
      "Authentication, sessions, registration, sign-in/sign-out, and password reset",
      "Protected dashboard",
      "Place and airport reference foundation"
    )
    expect(readme).not_to include("auth, and admin product behavior should be added later")
  end

  it "allows only stable Make verification targets in the project Codex rule" do
    expect(codex_rules).to include(
      '"make"',
      '"agent-rspec"',
      '"agent-test"',
      '"agent-verify-fast"',
      '"verify-fast"',
      '"verify"',
      '"security"',
      '"openspec-validate"',
      '"Stable non-destructive Routeprint verification targets"'
    )
    expect(codex_rules).not_to include('"docker"', '"compose"', '"bundle"', '"exec"', '"rspec"')
  end
end
