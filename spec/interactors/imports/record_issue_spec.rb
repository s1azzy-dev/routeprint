require "rails_helper"

RSpec.describe Imports::RecordIssue, type: :interactor do
  subject(:result) do
    described_class.call(
      input: {
        run:,
        run_item:,
        source_record:,
        stage: "normalize",
        code: "invalid_coordinate",
        severity: "error",
        message: "latitude is outside the valid range",
        details: { "field" => "latitude" },
        row_locator: "row:12"
      }
    )
  end

  let!(:run) { create(:imports_run, status: "running") }
  let!(:run_item) { create(:imports_run_item, run:) }
  let!(:source_record) { create(:imports_source_record, source: run.source, last_import_run: run) }

  it "persists a sanitized issue and marks the source record unresolved" do
    expect { result }.to change(Imports::Issue, :count).by(1)

    expect(result).to be_success
    expect(source_record.reload.status).to eq("unresolved")
    expect(run.reload.issue_count).to eq(1)
    expect(run_item.reload.stats).to include("issue_count" => 1)
    expect(result.value!.fetch(:issue)).to have_attributes(
      stage: "normalize",
      code: "invalid_coordinate",
      severity: "error",
      status: "open",
      message: "latitude is outside the valid range"
    )
  end
end
