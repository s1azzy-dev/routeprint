require "rails_helper"

RSpec.describe Imports::RunItemJob, type: :job do
  it "delegates to the run-item processor with only the item id" do
    allow(Imports::ProcessRunItem).to receive(:call).and_return(Dry::Monads::Success())

    described_class.perform_now(123)

    expect(Imports::ProcessRunItem).to have_received(:call).with(input: { run_item_id: 123 })
  end

  it "uses the imports queue" do
    expect(described_class.queue_name).to eq("imports")
  end
end
