# frozen_string_literal: true

require "rails_helper"

RSpec.describe Imports::Countries::Processor, type: :interactor do
  subject(:result) { described_class.call(input: { run:, item: }, downloader:) }

  let(:settings) { ApplicationConfig.config.imports.countries }
  let!(:source) { create(:imports_source, key: settings.source_key, provider_key: "routeprint", dataset_key: "country_catalog", target_kind: "country") }
  let!(:run) { create(:imports_run, source:, status: "running") }
  let!(:item) { create(:imports_run_item, run:, item_key: "all", status: "running", params: { "artifacts" => descriptors }) }
  let(:downloader) { class_double(Imports::Countries::Download) }
  let(:descriptors) do
    [
      { "key" => "ourairports_countries", "provider_key" => "ourairports", "dataset_key" => "countries", "source_url" => "https://ourairports.com/data/countries.csv", "filename" => "countries.csv", "content_type" => "text/csv" },
      { "key" => "cldr_territories_en", "provider_key" => "unicode_cldr", "dataset_key" => "territories", "locale" => "en", "source_url" => "https://raw.githubusercontent.com/en.json", "filename" => "en.json", "content_type" => "application/json" },
      { "key" => "cldr_territories_ru", "provider_key" => "unicode_cldr", "dataset_key" => "territories", "locale" => "ru", "source_url" => "https://raw.githubusercontent.com/ru.json", "filename" => "ru.json", "content_type" => "application/json" }
    ]
  end

  before do
    allow(downloader).to receive(:call).and_return(Dry::Monads::Failure(code: :unexpected_download, errors: {}))
    capture("ourairports_countries", "id,code,name,continent\n302672,XK,Kosovo,EU\n", "text/csv")
    capture("cldr_territories_en", territories_document("en", "Kosovo"), "application/json")
    capture("cldr_territories_ru", territories_document("ru", "Косово"), "application/json")
  end

  it "stages all provider artifacts then applies one catalog transaction" do
    expect { result }.to change(Country, :count).by(1)
      .and change(CountryName, :count).by(2)

    expect(result).to be_success
    expect(source.source_records).to all(be_status_applied)
    expect(item.artifacts.map { |artifact| artifact.metadata.fetch("provider") }).to contain_exactly(
      "ourairports", "unicode_cldr", "unicode_cldr"
    )
  end

  it "does not apply canonical records when one package artifact is unavailable" do
    item.artifacts.find_by("metadata ->> 'artifact_key' = ?", "cldr_territories_ru").destroy!

    expect(result).to be_failure
    expect(result.failure[:code]).to eq(:unexpected_download)
    expect(Country).not_to exist
  end

  private

  def capture(artifact_key, body, content_type)
    Imports::CaptureArtifact.call(
      input: {
        run:, run_item: item, kind: "source_dump", io: StringIO.new(body), filename: "#{artifact_key}.data", content_type:,
        metadata: { "artifact_key" => artifact_key, "provider" => artifact_key.start_with?("ourairports") ? "ourairports" : "unicode_cldr" }
      }
    )
  end

  def territories_document(locale, name)
    { "main" => { locale => { "localeDisplayNames" => { "territories" => { "XK" => name } } } } }.to_json
  end
end
