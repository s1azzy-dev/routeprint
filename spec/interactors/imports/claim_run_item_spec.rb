require "rails_helper"

RSpec.describe Imports::ClaimRunItem, type: :interactor do
  subject(:result) { described_class.call(input: { run_item_id: item.id, lease_seconds: 300 }) }

  let!(:run) { create(:imports_run, status: "queued") }
  let!(:item) { create(:imports_run_item, run:, status: "queued") }

  it "claims a queued item with an execution lease and moves the parent run to running" do
    expect(result).to be_success

    expect(item.reload).to have_attributes(status: "running", attempts_count: 1)
    expect(item.lease_token).to be_present
    expect(item.lease_expires_at).to be > Time.current
    expect(run.reload).to have_attributes(status: "running")
  end
end
