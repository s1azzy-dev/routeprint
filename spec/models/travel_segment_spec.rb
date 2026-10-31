require "rails_helper"

RSpec.describe TravelSegment do
  it "persists a date-only owned flight without inventing timestamps" do
    flight = create(:travel_segment)
    expect(flight.reload).to have_attributes(transport_mode: "flight", departure_date: Date.new(2020, 6, 1))
    expect(flight.departure_local_at).to be_nil
    expect(flight.departure_at).to be_nil
    expect(flight.flight_detail).to be_present
  end

  it "enforces required ownership at the database boundary" do
    flight = create(:travel_segment)
    expect do
      described_class.transaction(requires_new: true) { flight.update_columns(user_id: nil) }
    end.to raise_error(ActiveRecord::NotNullViolation)
  end

  it "protects referenced airport places from deletion" do
    flight = create(:travel_segment)
    expect { flight.departure_place.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
    expect(flight.reload.departure_place).to be_present
  end

  it "destroys the specialization but preserves reference catalogs" do
    flight = create(:travel_segment)
    detail = flight.flight_detail
    airport = flight.departure_place
    flight.destroy!
    expect(FlightDetail.exists?(detail.id)).to be(false)
    expect(Place.exists?(airport.id)).to be(true)
  end

  it "enforces owner-scoped submission identity at the database boundary" do
    flight = create(:travel_segment)
    expect do
      described_class.transaction(requires_new: true) do
        flight.dup.save!(validate: false)
      end
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
