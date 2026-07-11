require "rails_helper"

RSpec.describe Imports::ReconcileMissingUpstream, type: :interactor do
  it "marks absent source records without deleting canonical airports" do
    source = create(:imports_source)
    run = create(:imports_run, source:, mode: "full", status: "running")
    airport = create(:airport)
    present = create(:imports_source_record, source:, last_import_run: run, status: "applied")
    absent = create(:imports_source_record, source:, status: "applied")
    create(:imports_airport_source_link, source_record: absent, airport:)

    result = described_class.call(input: { run: })

    expect(result).to be_success
    expect_reconciled_records(result, present:, absent:, airport:)
  end

  private

  def expect_reconciled_records(result, present:, absent:, airport:)
    expect(result.value!.fetch(:marked_count)).to eq(1)
    expect(present.reload).to be_status_applied
    expect(absent.reload).to be_status_missing_upstream
    expect(airport.reload).to be_present
    expect(Place.exists?(airport.place_id)).to be(true)
  end

  it "does nothing for incremental runs" do
    run = create(:imports_run, mode: "incremental", status: "running")
    record = create(:imports_source_record, source: run.source, status: "applied")

    expect(described_class.call(input: { run: }).value!.fetch(:marked_count)).to eq(0)
    expect(record.reload).to be_status_applied
  end
end
