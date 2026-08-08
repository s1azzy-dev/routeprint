require "rails_helper"

RSpec.describe Airlines::Search, type: :interactor do
  subject(:result) do
    described_class.call(input: { query:, flight_date: })
  end

  let(:query) { "air" }
  let(:flight_date) { nil }

  it "searches selectable airlines by normalized name and ranks approved before pending" do
    pending = create(:airline, name: "Air Alpha")
    approved = create(:airline, :approved, name: "Air Beta")
    create(:airline, :approved, name: "Different Carrier")

    expect(result).to be_success
    expect(airlines).to eq([ approved, pending ])
  end

  it "returns every selectable candidate sharing an IATA designator" do
    first = create(:airline, :approved, name: "First Carrier")
    second = create(:airline, :approved, name: "Second Carrier")
    create(:airline_designator, airline: first, system: "iata", code: "ZZ")
    create(:airline_designator, airline: second, system: "iata", code: "ZZ")

    result = described_class.call(input: { query: "zz", flight_date: nil })

    expect(result).to be_success
    expect(result.value!.fetch(:airlines)).to contain_exactly(first, second)
  end

  it "searches ICAO designators" do
    airline = create(:airline, :approved)
    create(:airline_designator, airline:, system: "icao", code: "ABC")

    result = described_class.call(input: { query: "abc", flight_date: nil })

    expect(result).to be_success
    expect(result.value!.fetch(:airlines)).to eq([ airline ])
  end

  it "ranks a date-compatible historical designator ahead of an incompatible current airline" do
    current = create(:airline, :approved, name: "Current Carrier", operational_status: "active")
    historical = create(:airline, :approved, :inactive, name: "Historical Carrier")
    create(:airline_designator, airline: current, system: "iata", code: "HX", valid_from: Date.new(2000, 1, 1))
    create(:airline_designator, airline: historical, system: "iata", code: "HX", valid_until: Date.new(1999, 12, 31))

    result = described_class.call(input: { query: "HX", flight_date: Date.new(1995, 6, 1) })

    expect(result).to be_success
    expect(result.value!.fetch(:airlines)).to eq([ historical, current ])
  end

  it "keeps inactive airlines selectable while excluding rejected, merged, and system records" do
    target = create(:airline, :approved, name: "Air Target")
    inactive = create(:airline, :approved, :inactive, name: "Air Historical")
    create(:airline, name: "Air Rejected", review_status: "rejected")
    create(:airline, name: "Air Merged", review_status: "merged", merged_into: target)
    create(:airline, :system_placeholder)

    expect(result).to be_success
    expect(airlines).to eq([ target, inactive ])
  end

  it "bounds the result set" do
    create_list(:airline, 21, :approved, name: "Air Match")

    expect(result).to be_success
    expect(airlines.size).to eq(described_class::RESULT_LIMIT)
  end

  it "rejects an empty query" do
    result = described_class.call(input: { query: "  ", flight_date: nil })

    expect(result).to be_failure
    expect(result.failure.fetch(:code)).to eq(:validation_error)
  end

  def airlines
    result.value!.fetch(:airlines)
  end
end
