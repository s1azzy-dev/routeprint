require "rails_helper"

RSpec.describe Imports::OurAirports::Airports::Eligibility do
  it "accepts fixed-wing airport types" do
    result = described_class.call("airport_type" => "small_airport")

    expect(result).to be_success
  end

  it "rejects types outside the fixed-wing catalog" do
    result = described_class.call("airport_type" => "heliport")

    expect(result).to be_failure
    expect(result.failure.fetch(:code)).to eq(:excluded_facility)
  end
end
