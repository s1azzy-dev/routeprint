require "rails_helper"

RSpec.describe Imports::CancelRun, type: :interactor do
  subject(:result) { described_class.call(input: { run_id: run.id }) }

  let!(:run) { create(:imports_run, status: "running") }
  let!(:queued_item) { create(:imports_run_item, run:, item_key: "queued", status: "queued") }
  let!(:running_item) { create(:imports_run_item, run:, item_key: "running", status: "running") }

  it "records cancellation and stops queued work" do
    expect(result).to be_success

    expect(run.reload.cancel_requested_at).to be_present
    expect(queued_item.reload).to have_attributes(status: "cancelled", finished_at: be_present)
    expect(running_item.reload.status).to eq("running")
  end
end
