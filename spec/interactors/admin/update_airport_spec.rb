require "rails_helper"

RSpec.describe Admin::UpdateAirport, type: :interactor do
  subject(:result) { described_class.call(input: { airport:, attributes: }) }

  let!(:airport) { create(:airport) }
  let(:attributes) do
    {
      name: "London Heathrow Airport",
      municipality_name: "London",
      country_code: "GB",
      region_code: "GB-ENG",
      time_zone: "Europe/London",
      operational_status: "closed",
      iata_code: "lhr",
      icao_code: "egll"
    }
  end

  it "updates the place and airport atomically" do
    expect(result).to be_success
    expect_updated_airport
  end

  it "does not partially persist invalid place attributes" do
    attributes[:time_zone] = "Not/A_Timezone"

    expect(result).to be_failure
    expect(result.failure.fetch(:code)).to eq(:validation_error)
    expect(airport.reload.operational_status).to eq("active")
    expect(airport.place.reload.name).to include("Airport")
  end

  it "preserves import provenance" do
    link = create(:imports_airport_source_link, airport:)

    expect(result).to be_success
    expect(link.reload.airport).to eq(airport)
  end

  private

  def expect_updated_airport
    expect(airport.reload).to have_attributes(
      operational_status: "closed",
      iata_code: "LHR",
      icao_code: "EGLL"
    )
    expect(airport.place.reload).to have_attributes(
      name: "London Heathrow Airport",
      municipality_name: "London",
      country_code: "GB",
      region_code: "GB-ENG",
      time_zone: "Europe/London"
    )
  end
end
