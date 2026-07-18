# frozen_string_literal: true

require "rails_helper"

RSpec.describe Imports::Countries::ApplyCatalog, type: :interactor do
  subject(:result) { described_class.call(input: { run_id: run.id }) }

  let(:settings) { ApplicationConfig.config.imports.countries }
  let!(:source) { create(:imports_source, key: settings.source_key, provider_key: "routeprint", dataset_key: "country_catalog", target_kind: "country") }
  let!(:run) { create(:imports_run, source:, status: "running") }

  before do
    create_country_record
    create_name_record("en", "Kosovo")
    create_name_record("ru", "Косово")
  end

  it "applies a complete package and records explicit provenance" do
    expect { result }.to change(Country, :count).by(1)
      .and change(CountryName, :count).by(2)
      .and change(Imports::CountrySourceLink, :count).by(1)
      .and change(Imports::CountryNameSourceLink, :count).by(2)

    expect(result).to be_success
    country = Country.find_by!(code: "XK")
    expect(country.name_for(:ru)).to eq("Косово")
    expect(source.source_records).to all(be_status_applied)
  end

  it "rejects an incomplete translation set without canonical writes" do
    source.source_records.find_by!(external_uid: "ru:XK").destroy!

    expect(result).to be_failure
    expect(result.failure[:code]).to eq(:country_catalog_incomplete)
    expect(Country).not_to exist
  end

  private

  def create_country_record
    create(
      :imports_source_record,
      source:,
      last_import_run: run,
      record_kind: "country",
      external_uid: "302672",
      normalized_payload: { "code" => "XK", "name" => "Kosovo", "continent_code" => "EU" }
    )
  end

  def create_name_record(locale, name)
    create(
      :imports_source_record,
      source:,
      last_import_run: run,
      record_kind: "country_name",
      external_uid: "#{locale}:XK",
      normalized_payload: { "code" => "XK", "locale" => locale, "name" => name }
    )
  end
end
