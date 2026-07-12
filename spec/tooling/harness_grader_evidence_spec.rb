# frozen_string_literal: true

require "fileutils"
require "json"
require "open3"
require "pathname"
require "tmpdir"

class HarnessGraderEvidence
end

RSpec.describe HarnessGraderEvidence do
  let(:root) { Pathname(__dir__).join("../..").expand_path }

  def load_harness_run
    load root.join("bin/harness-run").to_s unless defined?(HarnessRun)
  end

  def run_grader(name, case_id, run_dir, worktree = root)
    output, error, status = Open3.capture3(
      root.join("bin/harness-graders", name).to_s,
      "--case", case_id,
      "--run-dir", run_dir.to_s,
      "--worktree", worktree.to_s
    )
    [ JSON.parse(output), error, status ]
  end

  # rubocop:disable RSpec/ExampleLength
  it "fails a required gate when the trace exit code is non-zero" do
    Dir.mktmpdir do |directory|
      run_dir = Pathname(directory)
      run_dir.join("trace.jsonl").write(
        JSON.generate(
          "type" => "item.completed",
          "item" => { "type" => "command_execution", "command" => "git diff --check", "exit_code" => 2 }
        ) + "\n"
      )

      result, _error, status = run_grader("tests", "docs-stale-baseline", run_dir)

      expect(status).to be_success
      expect(result.fetch("passed")).to be(false)
      expect(result.fetch("final_gates").first.fetch("status")).to eq("failed")
    end
  end
  # rubocop:enable RSpec/ExampleLength

  it "includes untracked files in changed-file evidence" do
    Dir.mktmpdir do |directory|
      worktree = Pathname(directory)
      system("git", "init", "-q", chdir: worktree.to_s)
      worktree.join("tracked.txt").write("tracked\n")
      system("git", "add", "tracked.txt", chdir: worktree.to_s)
      system("git", "-c", "user.name=Spec", "-c", "user.email=spec@example.test", "commit", "-qm", "base", chdir: worktree.to_s)
      worktree.join("untracked_spec.rb").write("RSpec.describe :example\n")

      load root.join("bin/harness-graders/support.rb").to_s
      changed = HarnessGraderSupport.changed_files(worktree)

      expect(changed).to include("untracked_spec.rb")
    end
  end

  it "times out a child process without requiring a Codex run" do
    load_harness_run
    Dir.mktmpdir do |directory|
      result = HarnessRun.execute_codex([ "/bin/sh", "-c", "sleep 2" ], Pathname(directory), 0.1)

      expect(result.fetch(:terminal_status)).to eq("timeout")
    end
  end

  it "keeps source hash stable when mutable tmp artifacts change" do
    load_harness_run
    first = HarnessEval.source_hash
    probe = root.join("tmp/harness-hash-probe")
    probe.write("mutable result\n")
    second = HarnessEval.source_hash
    FileUtils.rm_f(probe)

    expect(second).to eq(first)
  end
end
