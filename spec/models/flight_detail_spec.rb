require "rails_helper"

RSpec.describe FlightDetail do
  it "stores carrier and observed-number evidence with an optional operator" do
    detail = create(:travel_segment).flight_detail
    detail.update!(flight_number: "AB123", marketing_designator: "OLD", operating_airline: nil)
    expect(detail.reload).to have_attributes(flight_number: "AB123", marketing_designator: "OLD", operating_airline_id: nil)
  end

  it "requires the marketing carrier at the database boundary" do
    detail = create(:travel_segment).flight_detail
    expect do
      described_class.transaction(requires_new: true) { detail.update_columns(marketing_airline_id: nil) }
    end.to raise_error(ActiveRecord::NotNullViolation)
  end

  it "protects referenced airlines from ordinary deletion" do
    detail = create(:travel_segment).flight_detail
    expect { detail.marketing_airline.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
  end
end
