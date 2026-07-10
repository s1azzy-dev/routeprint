require "rails_helper"

RSpec.describe Imports::ProcessRunItem, type: :interactor do
  subject(:result) { described_class.call(input: { run_item_id: item.id }, processor:) }

  let!(:run) { create(:imports_run, status: "running") }
  let!(:item) { create(:imports_run_item, run:, item_key: "all", status:) }
  let(:status) { "queued" }
  let(:processor) { class_double(Imports::SourceProcessor) }

  before do
    allow(processor).to receive(:call).and_return(Dry::Monads::Success(stats: { "processed_count" => 1 }))
  end

  it "processes a queued item and finalizes the parent run" do
    expect(result).to be_success

    expect(processor).to have_received(:call).with(input: { run:, item: an_instance_of(Imports::RunItem) })
    expect(item.reload).to have_attributes(status: "succeeded", attempts_count: 1)
    expect(run.reload.status).to eq("succeeded")
  end

  context "when the item already succeeded" do
    let(:status) { "succeeded" }

    it "skips processor work" do
      expect(result).to be_success
      expect(result.value!).to include(skipped: true)
      expect(processor).not_to have_received(:call)
    end
  end

  context "when the item has a live lease" do
    let(:status) { "running" }

    before { item.update!(lease_token: SecureRandom.uuid, lease_expires_at: 5.minutes.from_now) }

    it "skips duplicate processor work" do
      expect(result).to be_success
      expect(result.value!).to include(skipped: true)
      expect(processor).not_to have_received(:call)
    end
  end
end
