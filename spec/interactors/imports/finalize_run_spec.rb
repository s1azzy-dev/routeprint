require "rails_helper"

RSpec.describe Imports::FinalizeRun, type: :interactor do
  subject(:result) { described_class.call(input: { run_id: run.id }) }

  let!(:run) { create(:imports_run, status: "running") }

  it "marks a terminal run partially failed and aggregates item counters" do
    create(:imports_run_item, run:, item_key: "succeeded", status: "succeeded", stats: { "processed_count" => 8 })
    create(:imports_run_item, run:, item_key: "failed", status: "failed", stats: { "processed_count" => 2 })

    expect(result).to be_success
    expect(run.reload).to have_attributes(
      status: "partially_failed",
      total_item_count: 2,
      completed_item_count: 1,
      failed_item_count: 1
    )
    expect(run.stats).to include("processed_count" => 10)
  end

  it "keeps a run active while an item is still queued" do
    create(:imports_run_item, run:, item_key: "queued", status: "queued")

    expect(result).to be_success
    expect(run.reload.status).to eq("running")
  end
end
