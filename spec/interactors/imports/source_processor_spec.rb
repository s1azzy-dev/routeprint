require "rails_helper"

RSpec.describe Imports::SourceProcessor, type: :interactor do
  let!(:run) { create(:imports_run, status: "running") }
  let!(:item) { create(:imports_run_item, run:, status: "running") }
  let(:airport_processor) { class_double(Imports::OurAirports::Airports::Processor, call: Dry::Monads::Success(stats: {})) }

  it "dispatches through the injected source processor" do
    result = described_class.call(input: { run:, item: }, airport_processor:)

    expect(result).to be_success
    expect(airport_processor).to have_received(:call).with(input: { run:, item: })
  end

  it "dispatches the composite country catalog processor" do
    run.source.update!(key: "country_catalog", provider_key: "routeprint", dataset_key: "country_catalog", target_kind: "country")
    country_catalog_processor = class_double(Imports::Countries::Processor, call: Dry::Monads::Success(stats: {}))

    result = described_class.call(input: { run:, item: }, country_catalog_processor:)

    expect(result).to be_success
    expect(country_catalog_processor).to have_received(:call).with(input: { run:, item: })
  end
end
