require "rails_helper"

RSpec.describe FlightDetail do
  it "requires a marketing carrier and normalizes optional flight number" do
    detail = build(:flight_detail, flight_number: " ab123 ")
    expect(detail).to be_valid
    expect(detail.flight_number).to eq("AB123")
    detail.marketing_airline = nil
    expect(detail).not_to be_valid
  end

  it "rejects malformed or oversized flight numbers" do
    [ "AB-123", "A" * 17 ].each do |number|
      expect(build(:flight_detail, flight_number: number)).not_to be_valid
    end
  end

  it "protects referenced airlines from ordinary deletion" do
    detail = create(:travel_segment).flight_detail
    expect { detail.marketing_airline.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
  end
end
