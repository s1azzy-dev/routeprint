require "rails_helper"

RSpec.describe Flights::PrepareEntry do
  let(:departure) { create(:airport).place }
  let(:arrival) { create(:airport).place }
  let(:attributes) do
    { departure_place_id: departure.id, arrival_place_id: arrival.id, departure_date: "2020-06-01" }
  end

  def prepare(changes = {})
    described_class.call(input: { attributes: attributes.merge(changes) })
  end

  it "rejects identical airports before a record is built or a carrier is bootstrapped" do
    result = nil
    expect { result = prepare(arrival_place_id: departure.id) }.not_to change(Airline, :count)
    expect(result).to be_failure
    expect(result.failure[:errors]).to have_key(:arrival_place_id)
  end

  it "rejects a non-airport endpoint at the use-case boundary" do
    place = create(:place)
    expect(prepare(arrival_place_id: place.id).failure[:errors]).to have_key(:arrival_place_id)
  end

  it "rejects invalid flight numbers before any persistence" do
    [ "AB-123", "A" * 17 ].each do |number|
      result = nil
      expect { result = prepare(flight_number: number) }.not_to change(Airline, :count)
      expect(result).to be_failure
      expect(result.failure[:errors]).to have_key(:flight_number)
    end
  end

  it "normalizes the optional number before returning persistence attributes" do
    expect(prepare(flight_number: " ab123 ").value![:detail][:flight_number]).to eq("AB123")
    expect(prepare(flight_number: " ").value![:detail][:flight_number]).to be_nil
  end

  it "rejects resolved reversed chronology before a model is saved" do
    result = prepare(departure_time: "15:00", arrival_date: "2020-06-01", arrival_time: "14:00")
    expect(result).to be_failure
    expect(result.failure[:errors]).to have_key(:arrival_date)
  end
end
