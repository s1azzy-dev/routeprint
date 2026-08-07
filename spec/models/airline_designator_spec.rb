require "rails_helper"

RSpec.describe AirlineDesignator, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:airline) }
  end

  describe "validations" do
    subject(:designator) { build(:airline_designator) }

    it { is_expected.to validate_inclusion_of(:system).in_array(%w[iata icao]) }
    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_uniqueness_of(:code).scoped_to(%i[airline_id system]).case_insensitive }
  end

  it "normalizes codes and accepts optional validity dates" do
    designator = build(:airline_designator, system: " ICAO ", code: " abc ", valid_from: nil, valid_until: nil)

    designator.validate

    expect(designator).to have_attributes(system: "icao", code: "ABC")
    expect(designator).to be_valid
  end

  it "allows the same designator for distinct airlines" do
    create(:airline_designator, system: "iata", code: "ZZ")

    expect(build(:airline_designator, system: "iata", code: "ZZ")).to be_valid
  end

  it "rejects an inverted validity range" do
    designator = build(:airline_designator, valid_from: Date.new(2020, 1, 2), valid_until: Date.new(2020, 1, 1))

    expect(designator).not_to be_valid
  end
end
