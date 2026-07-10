require "rails_helper"

RSpec.describe Imports::RecoverStaleRunItems, type: :interactor do
  subject(:result) { described_class.call(input: { run_id: run.id }) }

  let!(:run) { create(:imports_run, status: "running") }
  let!(:stale_item) do
    create(
      :imports_run_item,
      run:,
      item_key: "stale",
      status: "running",
      checkpoint: { "row" => 10 },
      attempts_count: 2,
      lease_token: SecureRandom.uuid,
      lease_expires_at: 1.minute.ago
    )
  end
  let!(:live_item) do
    create(
      :imports_run_item,
      run:,
      item_key: "live",
      status: "running",
      lease_token: SecureRandom.uuid,
      lease_expires_at: 5.minutes.from_now
    )
  end

  it "requeues only expired leases and preserves checkpoints" do
    expect(result).to be_success
    expect(result.value![:items]).to contain_exactly(stale_item)
    expect(stale_item.reload).to have_attributes(status: "queued", lease_token: nil, lease_expires_at: nil, attempts_count: 2)
    expect(stale_item.checkpoint).to eq("row" => 10)
    expect(live_item.reload.status).to eq("running")
  end
end
