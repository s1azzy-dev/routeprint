require "rails_helper"

RSpec.describe Imports::OurAirports::Airports::Parser do
  it "parses CSV rows while retaining row number and raw payload" do
    rows = described_class.call(File.open(Rails.root.join("spec/fixtures/imports/ourairports_airports.csv")))

    expect(rows.size).to eq(9)
    expect(rows.first).to include(row_number: 2)
    expect(rows.first.fetch(:raw_payload)).to include("id" => "35167", "type" => "small_airport")
  end
end
