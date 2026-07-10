require "rails_helper"

RSpec.describe Imports::OurAirports::Airports::Normalizer do
  let(:row) do
    {
      "id" => "1",
      "ident" => "EGLL",
      "type" => "large_airport",
      "name" => " London Heathrow ",
      "latitude_deg" => "51.4706",
      "longitude_deg" => "-0.461941",
      "continent" => "eu",
      "iso_country" => "gb",
      "iso_region" => "gb-eng",
      "municipality" => "London",
      "icao_code" => "EGLL",
      "iata_code" => "lhr"
    }
  end

  it "uses the provider row id as identity and normalizes catalog fields" do
    result = described_class.call(row)

    expect(result).to be_success
    expect(result.value!).to include(external_uid: "1", record_kind: "airport")
    expect(result.value!.fetch(:normalized_payload)).to include(
      "name" => "London Heathrow",
      "country_code" => "GB",
      "iata_code" => "LHR",
      "icao_code" => "EGLL",
      "operational_status" => "active"
    )
  end

  it "rejects excluded facility types and invalid coordinates" do
    excluded = described_class.call(row.merge("type" => "heliport"))
    invalid = described_class.call(row.merge("latitude_deg" => "91"))

    expect(excluded).to be_failure
    expect(excluded.failure.fetch(:code)).to eq(:unsupported_facility_type)
    expect(invalid.failure.fetch(:code)).to eq(:invalid_coordinates)
  end

  it "rejects an invalid supplied timezone" do
    result = described_class.call(row.merge("time_zone" => "Mars/Phobos"))

    expect(result).to be_failure
    expect(result.failure.fetch(:code)).to eq(:invalid_timezone)
  end
end
