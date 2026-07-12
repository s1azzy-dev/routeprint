# frozen_string_literal: true

require "json"
require "open3"
require "optparse"
require "pathname"

load File.expand_path("../harness-eval", __dir__)

module HarnessGraderSupport
  ROOT = Pathname(__dir__).join("../..").expand_path.freeze

  module_function

  def options(argv)
    values = {}
    parser = OptionParser.new do |opts|
      opts.on("--case ID") { |value| values[:case_id] = value }
      opts.on("--run-dir PATH") { |value| values[:run_dir] = Pathname(value).expand_path }
      opts.on("--worktree PATH") { |value| values[:worktree] = Pathname(value).expand_path }
    end
    parser.parse!(argv)
    required = values.values_at(:case_id, :run_dir, :worktree)
    raise ArgumentError, "--case, --run-dir, and --worktree are required" unless required.all?

    values[:case] = HarnessEval.find_case(values[:case_id])
    values
  end

  def trace_events(run_dir)
    path = run_dir.join("trace.jsonl")
    return [] unless path.file?

    path.readlines.map { |line| JSON.parse(line) rescue nil }.compact
  end

  def trace_text(run_dir)
    path = run_dir.join("trace.jsonl")
    path.file? ? path.read : ""
  end

  def command_executions(run_dir)
    trace_events(run_dir).map do |event|
      item = event["item"]
      item if event["type"] == "item.completed" && item.is_a?(Hash) && item["type"] == "command_execution"
    end.compact
  end

  def command_matches?(actual, expected)
    return false unless actual && expected

    actual.include?(expected) || expected.split.all? { |token| actual.include?(token) }
  end

  def command_statuses(run_dir, commands)
    commands.map do |expected|
      attempts = command_executions(run_dir).select do |execution|
        command_matches?(execution["command"].to_s, expected)
      end
      status = if attempts.empty?
                 "missing"
      elsif attempts.any? { |attempt| attempt["exit_code"] == 0 }
                 "passed"
      elsif attempts.any? { |attempt| blocked_output?(attempt["aggregated_output"]) }
                 "blocked"
      else
                 "failed"
      end
      {
        "command" => expected,
        "status" => status,
        "exit_codes" => attempts.map { |attempt| attempt["exit_code"] },
        "attempts" => attempts.size
      }
    end
  end

  def blocked_output?(output)
    output.to_s.match?(/permission denied|address already in use|port .* conflict|blocked|operation not permitted/i)
  end

  def changed_files(worktree)
    tracked = git_output(worktree, "diff", "HEAD", "--name-only")
    untracked = git_output(worktree, "ls-files", "--others", "--exclude-standard")
    (tracked.lines + untracked.lines).map(&:strip).reject(&:empty?).uniq.sort
  end

  def diff_text(worktree)
    tracked = git_output(worktree, "diff", "HEAD")
    untracked = changed_files(worktree).select do |path|
      git_output(worktree, "ls-files", "--others", "--exclude-standard").lines.map(&:strip).include?(path)
    end.map do |path|
      absolute = worktree.join(path)
      "\n+++ #{path}\n#{absolute.file? ? absolute.read : ""}"
    end.join
    tracked + untracked
  end

  def git_output(worktree, *args)
    output, _error, _status = Open3.capture3("git", "-C", worktree.to_s, *args)
    output
  end

  def matches_path?(pattern, path)
    pattern == path ||
      (pattern.end_with?("/**") && path.start_with?(pattern.delete_suffix("/**") + "/")) ||
      File.fnmatch?(pattern, path)
  end

  def emit(payload)
    puts JSON.generate(payload)
  end
end
