require "rails_helper"

RSpec.describe Imports::Run, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:source).class_name("Imports::Source") }
    it { is_expected.to belong_to(:retry_of_run).class_name("Imports::Run").optional }
    it { is_expected.to belong_to(:initiated_by).class_name("User").optional }
    it { is_expected.to have_many(:items).class_name("Imports::RunItem").dependent(:restrict_with_exception) }
    it { is_expected.to have_many(:retry_runs).class_name("Imports::Run").dependent(:nullify) }
    it { is_expected.to have_many(:source_records).class_name("Imports::SourceRecord").dependent(:nullify) }
    it { is_expected.to have_many(:artifacts).class_name("Imports::Artifact").dependent(:restrict_with_exception) }
  end

  describe "validations" do
    subject(:run) { described_class.new(source: Imports::Source.new, mode: "full", status: "queued") }

    it "defines the mode and status vocabularies" do
      expect(described_class::MODES).to contain_exactly("full", "incremental", "replay", "retry")
      expect(described_class::STATUSES).to contain_exactly("queued", "running", "succeeded", "partially_failed", "failed")
    end
  end

  it "exposes only queued and running runs as active" do
    expect(described_class.active.to_sql).to include("queued")
    expect(described_class.active.to_sql).to include("running")
  end
end
