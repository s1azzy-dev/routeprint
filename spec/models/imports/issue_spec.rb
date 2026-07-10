require "rails_helper"

RSpec.describe Imports::Issue, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:run).class_name("Imports::Run") }
    it { is_expected.to belong_to(:run_item).class_name("Imports::RunItem").optional }
    it { is_expected.to belong_to(:source_record).class_name("Imports::SourceRecord").optional }
  end

  describe "validations" do
    subject(:issue) do
      described_class.new(
        run: Imports::Run.new,
        stage: "parse",
        code: "invalid_row",
        severity: "error",
        status: "open",
        message: "invalid row"
      )
    end

    it { is_expected.to validate_inclusion_of(:stage).in_array(described_class::STAGES) }

    it "defines the enum vocabularies" do
      expect(described_class::SEVERITIES).to contain_exactly("warning", "error")
      expect(described_class::STATUSES).to contain_exactly("open", "resolved", "ignored")
    end

    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_presence_of(:message) }
  end
end
