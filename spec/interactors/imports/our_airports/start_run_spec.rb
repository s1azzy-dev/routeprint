require "rails_helper"

RSpec.describe Imports::OurAirports::StartRun, type: :interactor do
  subject(:result) { described_class.call(input: { initiated_by_user_id: }, start_run:) }

  let(:start_run) { class_double(Imports::StartRun, call: Dry::Monads::Success(run: :run, items: :items)) }
  let(:initiated_by_user_id) { SecureRandom.uuid }
  let(:settings) { ApplicationConfig.config.imports.ourairports }
  let(:expected_input) do
    {
      source_key: settings.source_key,
      mode: "full",
      params: { "source_url" => settings.source_url, "parser_version" => "1" },
      items: [
        {
          item_kind: "file",
          item_key: "all",
          params: { "source_url" => settings.source_url }
        }
      ],
      initiated_by_user_id:
    }
  end

  it "builds the generic start input from application settings" do
    expect(result).to be_success
    expect(start_run).to have_received(:call).with(input: expected_input)
  end
end
