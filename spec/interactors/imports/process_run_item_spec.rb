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

  context "when the item is already running" do
    let(:status) { "running" }

    it "skips duplicate processor work" do
      expect(result).to be_success
      expect(result.value!).to include(skipped: true)
      expect(processor).not_to have_received(:call)
    end
  end

  context "when the processor raises" do
    before { allow(processor).to receive(:call).and_raise(StandardError, "provider failure") }

    it "marks the item failed and finalizes the parent run" do
      expect(result).to be_success
      expect(item.reload).to have_attributes(status: "failed", error_code: "processor_error")
      expect(JSON.parse(item.error_message)).to include(
        "exception_class" => [ "StandardError" ],
        "exception_message" => [ "provider failure" ]
      )
      expect(JSON.parse(item.error_message).fetch("backtrace")).to be_an(Array)
      expect(run.reload.status).to eq("failed")
    end
  end
end
