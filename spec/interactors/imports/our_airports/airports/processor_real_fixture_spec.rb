require "rails_helper"

RSpec.describe Imports::OurAirports::Airports::Processor, type: :interactor do
  let!(:run) { create(:imports_run, status: "running", mode: "full") }
  let!(:item) { create(:imports_run_item, run:, status: "running", item_kind: "file", item_key: "airports") }
  let(:fixture_path) { Rails.root.join("spec/fixtures/imports/ourairports_airports.csv") }
  let!(:artifact) do
    Imports::CaptureArtifact.call(
      input: {
        run:,
        run_item: item,
        io: File.open(fixture_path),
        filename: "airports.csv",
        content_type: "text/csv",
        kind: "source_dump",
        source_url: "https://ourairports.com/data/airports.csv"
      }
    ).value!.fetch(:artifact)
  end

  it "processes real provider rows through the complete adapter path" do
    expect { result }.to change(Place, :count).by(9)
      .and change(Airport, :count).by(9)
      .and change(Imports::SourceRecord, :count).by(9)
      .and change(Imports::AirportSourceLink, :count).by(9)

    expect(result).to be_success
    expect(result.value!.fetch(:stats)).to include("processed_count" => 9, "succeeded_count" => 9, "issue_count" => 0)
    expect_real_airport
  end

  private

  def expect_real_airport
    airport = Airport.find_by!(iata_code: "HIR")
    expect(airport).to have_attributes(icao_code: "AGGH", operational_status: "active")
    expect(airport.place).to have_attributes(
      name: "Honiara International Airport",
      country_code: "SB",
      region_code: "SB-GU",
      municipality_name: "Honiara"
    )
    expect(airport.place.location.longitude).to be_within(0.000001).of(160.054993)
    expect(airport.place.location.latitude).to be_within(0.000001).of(-9.428)
    expect(Imports::SourceRecord.find_by!(external_uid: "3").airport_source_link.airport).to eq(airport)
  end

  private

  def result
    @result ||= Imports::OurAirports::Airports::Processor.call(input: { run:, item: })
  end
end
