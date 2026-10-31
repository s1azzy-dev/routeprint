require "rails_helper"

RSpec.describe Flights::Create do
  let(:user) { create(:user) }
  let(:departure) { create(:airport).place }
  let(:arrival) { create(:airport).place }
  let(:attributes) do
    { departure_place_id: departure.id, arrival_place_id: arrival.id,
      departure_date: "2020-06-01", creation_request_key: SecureRandom.uuid }
  end

  before { Airlines::BootstrapUnknown.call }

  def add(values = attributes, owner = user)
    Flights::Create.call(input: { user: owner, attributes: values })
  end

  it "creates date-only evidence and assigns the protected unknown airline" do
    result = add
    expect(result).to be_success
    flight = result.value![:flight].reload
    expect(flight.user).to eq(user)
    expect(flight.flight_detail.marketing_airline.system_key).to eq("unknown_airline")
    expect(flight.departure_at).to be_nil
    expect(flight.departure_resolution).to eq("date_only")
  end

  it "rejects invalid route, dates, times and unavailable carriers without writes" do
    rejected = create(:airline, review_status: "rejected")
    [ { departure_date: "2020-06" }, { departure_date: "2020-02-31" },
      { departure_date: "2999-01-01" }, { departure_time: "25:00" },
      { arrival_time: "14:00" }, { arrival_place_id: departure.id },
      { marketing_airline_id: rejected.id }, { flight_number: "A-123" } ].each do |changes|
      expect { expect(add(attributes.merge(changes))).to be_failure }.not_to change(TravelSegment, :count)
    end
  end

  it "warns about similar flights and allows explicit confirmation" do
    expect(add).to be_success
    repeated = attributes.merge(creation_request_key: SecureRandom.uuid)
    result = add(repeated)
    expect(result.failure[:code]).to eq(:duplicate_candidates)
    expect(add(repeated.merge(confirmed_duplicate: true))).to be_success
    expect(user.travel_segments.count).to eq(2)
  end

  it "replays one creation and conflicts on changed values" do
    first = add.value![:flight]
    expect(add.value![:flight].id).to eq(first.id)
    result = add(attributes.merge(flight_number: "AB1"))
    expect(result.failure[:code]).to eq(:submission_conflict)
    expect(user.travel_segments.count).to eq(1)
  end

  it "does not warn about other owners' records" do
    expect(add).to be_success
    expect(add(attributes, create(:user))).to be_success
  end

  it "does not partially persist an invalid specialization" do
    expect { expect(add(attributes.merge(flight_number: "AB-1"))).to be_failure }
      .not_to change { [ TravelSegment.count, FlightDetail.count ] }
  end

  it "keeps rejected carrier references readable and requires replacement on edit" do
    airline = create(:airline)
    flight = add(attributes.merge(marketing_airline_id: airline.id)).value![:flight]
    airline.update!(review_status: "rejected")
    expect(flight.reload.flight_detail.marketing_airline).to eq(airline)
    expect(Flights::Update.call(input: { user:, flight_id: flight.id,
      attributes: attributes.merge(marketing_airline_id: airline.id) })).to be_failure
    expect(Flights::Update.call(input: { user:, flight_id: flight.id, attributes: })).to be_success
  end

  it "accepts missing-zone times without inventing absolute evidence" do
    departure.update!(time_zone: nil, time_zone_source: nil, time_zone_verified_at: nil)
    flight = add(attributes.merge(departure_time: "12:30")).value![:flight]
    expect(flight.departure_resolution).to eq("missing_zone")
    expect(flight.departure_at).to be_nil
  end

  it "handles date-line arrival and explicitly re-resolves edited events" do
    departure.update!(time_zone: "Pacific/Auckland")
    arrival.update!(time_zone: "Pacific/Honolulu")
    values = attributes.merge(departure_time: "00:30", arrival_date: "2020-05-31", arrival_time: "12:00")
    flight = add(values).value![:flight]
    expect(flight.arrival_at).to be > flight.departure_at
    departure.update!(time_zone: "UTC")
    result = Flights::Update.call(input: { user:, flight_id: flight.id,
      attributes: values.merge(departure_time: "00:45", arrival_date: "2020-06-01") })
    expect(result).to be_success
    expect(flight.reload.departure_time_zone).to eq("UTC")
  end

  it "preserves unresolved times but rejects resolved reversed chronology" do
    expect(add(attributes.merge(departure_date: "2020-10-25", departure_time: "01:30"))).to be_success
    flight = user.travel_segments.last
    expect(flight.departure_resolution).to eq("ambiguous")
    expect(flight.departure_at).to be_nil
    invalid = attributes.merge(departure_time: "15:00", arrival_date: "2020-06-01", arrival_time: "14:00")
    expect(add(invalid)).to be_failure
  end

  it "preserves time evidence on unrelated edits after catalog correction" do
    flight = add(attributes.merge(departure_time: "12:30")).value![:flight]
    departure.update!(time_zone: "Asia/Tokyo")
    result = Flights::Update.call(input: { user:, flight_id: flight.id,
      attributes: attributes.merge(departure_time: "12:30", flight_number: "AB1") })
    expect(result).to be_success
    expect(flight.reload.departure_time_zone).to eq("Europe/London")
    expect(flight.departure_at).to eq(Time.utc(2020, 6, 1, 11, 30))
  end

  it "denies nonowners including admins and supports deliberate owner deletion" do
    flight = add.value![:flight]
    intruder = create(:user, role: "admin")
    expect(Flights::Update.call(input: { user: intruder, flight_id: flight.id, attributes: }).failure[:code]).to eq(:not_found)
    expect(Flights::Delete.call(input: { user: intruder, flight_id: flight.id, confirmed: true })).to be_failure
    expect(Flights::Delete.call(input: { user:, flight_id: flight.id, confirmed: false })).to be_failure
    expect(Flights::Delete.call(input: { user:, flight_id: flight.id, confirmed: true })).to be_success
    expect(TravelSegment.exists?(flight.id)).to be(false)
  end
end
