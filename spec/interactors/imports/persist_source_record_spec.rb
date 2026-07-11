require "rails_helper"

RSpec.describe Imports::PersistSourceRecord, type: :interactor do
  subject(:result) { described_class.call(input: { source:, run:, record: }) }

  let!(:source) { create(:imports_source) }
  let!(:run) { create(:imports_run, source:, status: "succeeded") }
  let(:record) do
    {
      record_kind: "airport",
      external_uid: "123",
      raw_payload: { "id" => 123, "name" => "Example" },
      normalized_payload: { "external_uid" => "123", "name" => "Example" }
    }
  end

  it "persists a source record and its first snapshot" do
    expect { result }.to change(Imports::SourceRecord, :count).by(1)
      .and change(Imports::RecordSnapshot, :count).by(1)

    expect(result).to be_success
    source_record = result.value!.fetch(:source_record)

    expect(source_record).to have_attributes(
      source:,
      record_kind: "airport",
      external_uid: "123",
      status: "staged",
      last_import_run: run
    )
    expect(source_record.snapshots.last).to have_attributes(run:, checksum: source_record.checksum)
  end

  it "does not create a snapshot when the payload checksum is unchanged" do
    described_class.call(input: { source:, run:, record: })

    expect { result }.not_to change(Imports::RecordSnapshot, :count)
  end

  it "creates a new snapshot when the normalized payload changes" do
    described_class.call(input: { source:, run:, record: })
    changed = record.merge(normalized_payload: record[:normalized_payload].merge("name" => "Changed"))

    expect { described_class.call(input: { source:, run:, record: changed }) }
      .to change(Imports::RecordSnapshot, :count).by(1)
  end
end
