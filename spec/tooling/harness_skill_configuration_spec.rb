# frozen_string_literal: true

require "pathname"
require "yaml"

class HarnessSkillConfiguration
end

RSpec.describe HarnessSkillConfiguration do
  let(:root) { Pathname(__dir__).join("../..").expand_path }
  let(:registry) { YAML.safe_load(root.join("harness/skills/cases.yml").read, aliases: false) }

  it "covers every Routeprint skill with positive and negative trigger cases" do
    registered = registry.fetch("skills")
    skill_ids = root.join(".agents/skills").glob("routeprint-*/SKILL.md").map { |path| path.dirname.basename.to_s }.sort

    expect(registered.map { |skill| skill.fetch("id") }).to match_array(skill_ids)
    registered.each do |skill|
      expect(skill.fetch("positive")).to all(be_a(String))
      expect(skill.fetch("negative")).to all(be_a(String))
      expect(skill.fetch("positive") & skill.fetch("negative")).to be_empty
    end
  end

  it "requires every trigger case to be non-empty" do
    registry.fetch("skills").each do |skill|
      %w[positive negative].each do |polarity|
        expect(skill.fetch(polarity)).to all(satisfy { |example| !example.strip.empty? })
      end
    end
  end
end
