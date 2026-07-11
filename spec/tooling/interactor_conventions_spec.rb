# frozen_string_literal: true

require "pathname"

class InteractorConventions
end

RSpec.describe InteractorConventions do
  let(:root) { Pathname(__dir__).join("../..").expand_path }
  let(:interactor_paths) do
    root.join("app/interactors").glob("**/*.rb").select do |path|
      path.read.include?("< ApplicationInteractor")
    end
  end
  let(:interactor_names) do
    interactor_paths.flat_map do |path|
      relative = path.relative_path_from(root.join("app/interactors")).sub_ext("")
      full_name = relative.each_filename.map { |segment| segment.split("_").map(&:capitalize).join }.join("::")

      [ full_name, full_name.split("::").last ]
    end.uniq
  end

  it "keeps real input contracts and concise class-level YARD documentation" do
    expect(interactor_paths).not_to be_empty

    interactor_paths.each do |path|
      content = path.read

      expect(content).to include("# @example"), path.to_s
      next unless content.match?(/^\s*option :input\b/)

      expect(content).to include("# @param input"), path.to_s
      expect(content).to match(/class ValidationContract.*?(?:required|optional)\(/m), path.to_s
    end
  end

  it "does not duplicate class-level YARD on interactor call methods" do
    interactor_paths.each do |path|
      call_comment_blocks = path.read.scan(/((?:^\s*#[^\n]*\n)+)^\s*def call\b/).flatten

      expect(call_comment_blocks.join).not_to include("# @"), path.to_s
    end
  end

  it "forbids direct constant calls to collaborators inside interactors" do
    direct_call_pattern = Regexp.union(
      interactor_names.map { |name| /(?<![A-Za-z0-9_:])#{Regexp.escape(name)}\.call\s*\(/ }
    )

    interactor_paths.each do |path|
      code = path.read.each_line.reject { |line| line.lstrip.start_with?("#") }.join

      expect(code).not_to match(direct_call_pattern), path.to_s
    end
  end
end
