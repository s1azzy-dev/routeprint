require "rails_helper"

RSpec.describe Airport, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:place) }
  end

  describe "validations" do
    subject(:airport) { build(:airport) }

    it { is_expected.to validate_presence_of(:operational_status) }
    it { is_expected.to validate_inclusion_of(:operational_status).in_array(described_class::OPERATIONAL_STATUSES) }
    it { is_expected.to allow_value(nil).for(:iata_code) }
    it { is_expected.to allow_value(nil).for(:icao_code) }
  end

  it "normalizes public codes to uppercase" do
    airport = build(:airport, iata_code: "lhr", icao_code: "egll")

    airport.validate

    expect(airport.iata_code).to eq("LHR")
    expect(airport.icao_code).to eq("EGLL")
  end

  it "rejects malformed public codes" do
    airport = build(:airport, iata_code: "12A", icao_code: "B4D")

    expect(airport).not_to be_valid
    expect(airport.errors[:iata_code]).to be_present
    expect(airport.errors[:icao_code]).to be_present
  end

  it "allows a historical code collision" do
    create(:airport, iata_code: "LHR", icao_code: "EGLL")
    historical = build(:airport, operational_status: "closed", iata_code: "lhr", icao_code: "egll")

    expect(historical).to be_valid
  end

  it "retains closed airports for historical travel" do
    airport = build(:airport, operational_status: "closed")

    expect(airport).to be_valid
  end

  it "keeps source classification and code identity out of the database schema" do
    expect(described_class.column_names).not_to include(
      "facility_kind", "size_class", "scheduled_service", "gps_code",
      "local_code", "elevation_m", "website_url"
    )

    code_indexes = ActiveRecord::Base.connection.indexes(:airports).select do |index|
      index.name.in?(%w[index_airports_on_iata_code index_airports_on_icao_code])
    end

    expect(code_indexes).to all(have_attributes(unique: false))
  end
end
