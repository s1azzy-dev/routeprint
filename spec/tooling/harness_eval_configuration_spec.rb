# frozen_string_literal: true

require "pathname"
require "yaml"

class HarnessEvalConfiguration
end

RSpec.describe HarnessEvalConfiguration do
  let(:root) { Pathname(__dir__).join("../..").expand_path }
  let(:registry) { YAML.safe_load(root.join("harness/evals/cases.yml").read, aliases: false) }
  let(:cases) { registry.fetch("cases") }
  let(:harness_readme) { root.join("harness/README.md").read }

  # This is an invariant matrix: each case must expose every required artifact.
  # rubocop:disable RSpec/MultipleExpectations
  it "registers at least ten complete cases" do
    expect(cases.size).to be >= registry.fetch("minimum_cases")
    expect(cases.map { |item| item.fetch("id") }.uniq.size).to eq(cases.size)

    cases.each do |item|
      expect(root.join(item.fetch("prompt_file"))).to be_file
      expect(item.fetch("graders")).not_to be_empty
      expect(item.fetch("rubrics")).not_to be_empty
      expect(item.fetch("required")).to include("commands", "final_gates")
      expect(item.fetch("required").keys & %w[files_any files_all files_or_patterns]).not_to be_empty
      expect(item.fetch("behavior")).to be_a(Hash)
      expect(item.fetch("timeout_seconds", registry.fetch("default_timeout_seconds"))).to be > 0
    end
  end
  # rubocop:enable RSpec/MultipleExpectations

  it "keeps every configured grader and rubric in the repository" do
    cases.each do |item|
      item.fetch("graders").each do |grader|
        path = root.join("bin/harness-graders", grader)
        expect(path).to be_file
        expect(path).to be_executable
      end

      item.fetch("rubrics").each do |rubric|
        expect(root.join("harness/evals/rubrics/#{rubric}.md")).to be_file
      end
    end
  end

  # rubocop:disable RSpec/ExampleLength
  it "defines comparable experiment metrics and safe raw-artifact paths" do
    results = root.join("harness/experiments/results.csv").read.lines.first

    expect(results).to include(
      "task_success", "diff_scope", "harness_hash"
    )
    expect(root.join("bin/harness-run").read).to include(
      "mechanical_pass", "workflow_pass", "behavior_pass", "cached_input_tokens"
    )
    expect(root.join("harness/experiments/reviews.csv").read.lines.first).to include(
      "reviewer", "correctness_score", "behavior_notes"
    )
    expect(root.join(".gitignore").read).to include("/tmp/harness-runs/", "/tmp/harness-worktrees/")
    expect(harness_readme).to include("codex exec --json", "workspace-write", "never commits", "smoke profile")
    expect(registry.fetch("profiles").fetch("smoke").size).to eq(3)
  end
  # rubocop:enable RSpec/ExampleLength

  it "exposes executable validation, run, and grading entrypoints" do
    %w[
      bin/harness-eval bin/harness-run bin/harness-graders/diff-scope
      bin/harness-graders/no-manual-schema bin/harness-graders/tests
      bin/harness-graders/workflow bin/harness-graders/behavior
      bin/harness-graders/dependency-approval
    ].each do |relative_path|
      expect(root.join(relative_path)).to be_executable
    end
  end

  it "hashes skill and permission policy with the eval harness" do
    load root.join("bin/harness-eval").to_s unless defined?(HarnessEval)
    source_files = HarnessEval.source_files

    expect(source_files).to include(
      ".codex/config.toml",
      ".codex/rules/rspec.rules",
      ".codex/agents/reviewer.toml",
      "harness/skills/cases.yml"
    )
  end
end
