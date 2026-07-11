require "rails_helper"

RSpec.describe Imports::SourceRecord, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:source).class_name("Imports::Source") }
    it { is_expected.to belong_to(:last_import_run).class_name("Imports::Run").optional }
    it { is_expected.to have_many(:snapshots).class_name("Imports::RecordSnapshot").dependent(:restrict_with_exception) }
    it { is_expected.to have_one(:airport_source_link).class_name("Imports::AirportSourceLink").dependent(:restrict_with_exception) }
    it { is_expected.to have_many(:issues).class_name("Imports::Issue").dependent(:nullify) }
  end

  describe "validations" do
    subject(:record) do
      described_class.new(
        source: Imports::Source.new,
        record_kind: "airport",
        external_uid: "123",
        status: "staged",
        checksum: "abc123"
      )
    end

    it { is_expected.to validate_presence_of(:record_kind) }
    it { is_expected.to validate_presence_of(:external_uid) }
    it { is_expected.to validate_presence_of(:checksum) }
  end

  it "defines the supported source-record statuses" do
    expect(described_class::STATUSES).to contain_exactly("staged", "applied", "unresolved", "missing_upstream")
  end

  it "normalizes the external identity" do
    record = described_class.new(record_kind: " airport ", external_uid: " 123 ")

    record.validate

    expect(record.record_kind).to eq("airport")
    expect(record.external_uid).to eq("123")
  end
end
