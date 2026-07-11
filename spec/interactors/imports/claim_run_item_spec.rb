require "rails_helper"

RSpec.describe Imports::ClaimRunItem, type: :interactor do
  subject(:result) { described_class.call(input: { run_item_id: item.id }) }

  let!(:run) { create(:imports_run, status: "queued") }
  let!(:item) { create(:imports_run_item, run:, status: "queued") }

  it "claims a queued item and moves the parent run to running" do
    expect(result).to be_success

    expect(item.reload).to have_attributes(status: "running", attempts_count: 1)
    expect(run.reload).to have_attributes(status: "running")
  end

  context "when the item is not queued" do
    before { item.update!(status: "running") }

    it "skips the item without changing its status" do
      expect(result).to be_success
      expect(result.value!).to include(skipped: true, reason: :not_queued)
      expect(item.reload).to have_attributes(status: "running", attempts_count: 0)
    end
  end
end
