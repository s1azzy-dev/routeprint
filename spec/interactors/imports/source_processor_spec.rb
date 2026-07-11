require "rails_helper"

RSpec.describe Imports::SourceProcessor, type: :interactor do
  let!(:run) { create(:imports_run, status: "running") }
  let!(:item) { create(:imports_run_item, run:, status: "running") }
  let(:processor) { class_double(Imports::OurAirports::Airports::Processor, call: Dry::Monads::Success(stats: {})) }

  it "dispatches through the injected source processor" do
    result = described_class.call(input: { run:, item: }, processor:)

    expect(result).to be_success
    expect(processor).to have_received(:call).with(input: { run:, item: })
  end
end
