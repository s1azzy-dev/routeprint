require "rails_helper"

RSpec.describe Imports::Artifact, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:run).class_name("Imports::Run") }
    it { is_expected.to belong_to(:run_item).class_name("Imports::RunItem").optional }
    it { is_expected.to have_one_attached(:file) }
  end

  describe "validations" do
    subject(:artifact) do
      described_class.new(
        run: Imports::Run.new,
        kind: "source_dump",
        sha256: "abc123",
        captured_at: Time.current
      )
    end

    it { is_expected.to validate_presence_of(:kind) }
    it { is_expected.to validate_presence_of(:sha256) }
    it { is_expected.to validate_presence_of(:captured_at) }
  end
end
