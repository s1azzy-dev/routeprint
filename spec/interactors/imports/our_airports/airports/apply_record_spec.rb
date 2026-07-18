require "rails_helper"

RSpec.describe Imports::OurAirports::Airports::ApplyRecord, type: :interactor do
  subject(:result) { described_class.call(input: { source_record: }) }

  let!(:source) { create(:imports_source) }
  let!(:country) { create(:country, code: "GB") }
  let(:source_record) do
    create(
      :imports_source_record,
      source:,
      normalized_payload: {
        "name" => "London Heathrow",
        "kind" => "airport",
        "airport_type" => "large_airport",
        "operational_status" => "active",
        "latitude" => 51.4706,
        "longitude" => -0.461941,
        "country_code" => "GB",
        "region_code" => "GB-ENG",
        "continent_code" => "EU",
        "municipality_name" => "London",
        "iata_code" => "LHR",
        "icao_code" => "EGLL"
      }
    )
  end

  it "creates a canonical airport and provider link" do
    expect { result }.to change(Place, :count).by(1)
      .and change(Airport, :count).by(1)
      .and change(Imports::AirportSourceLink, :count).by(1)

    expect(result).to be_success
    airport = result.value!.fetch(:airport)
    expect_created_airport(airport)
  end

  private

  def expect_created_airport(airport)
    expect(airport).to have_attributes(iata_code: "LHR", icao_code: "EGLL")
    expect(source_record.reload).to be_status_applied
    expect(source_record.airport_source_link.match_strategy).to eq("created_from_source")
    expect(airport.place.location.longitude).to be_within(0.000001).of(-0.461941)
    expect(airport.place.location.latitude).to be_within(0.000001).of(51.4706)
    expect(airport.place.country).to eq(country)
  end

  it "reuses an existing link on reimport" do
    described_class.call(input: { source_record: })

    expect { described_class.call(input: { source_record: source_record.reload }) }
      .not_to change(Place, :count)
    expect(source_record.airport_source_link.reload.match_strategy).to eq("created_from_source")
  end

  it "does not merge when incoming codes match multiple canonical airports" do
    create(:airport, iata_code: "LHR", icao_code: "AAAA")
    create(:airport, iata_code: "LHR", icao_code: "BBBB")

    expect(result).to be_failure
    expect(result.failure.fetch(:code)).to eq(:ambiguous_code_match)
    expect(source_record.reload).to be_status_staged
    expect(source_record.airport_source_link).to be_nil
  end

  it "keeps an airport record staged when its country is absent from the catalog" do
    country.destroy!

    expect(result).to be_failure
    expect(result.failure[:code]).to eq(:country_not_found)
    expect(source_record.reload).to be_status_staged
  end
end
