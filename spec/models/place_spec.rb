require "rails_helper"

RSpec.describe Place, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:place_names).dependent(:destroy) }
    it { is_expected.to have_one(:airport).dependent(:destroy) }
  end

  describe "validations" do
    subject(:place) { build(:place) }

    it { is_expected.to validate_presence_of(:kind) }
    it { is_expected.to validate_inclusion_of(:kind).in_array(described_class::KINDS) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:country_code) }
    it { is_expected.to validate_presence_of(:location) }
  end

  it "normalizes the canonical name and country code" do
    place = build(:place, name: "  London Heathrow  ", country_code: "gb")

    place.validate

    expect(place.name).to eq("London Heathrow")
    expect(place.country_code).to eq("GB")
  end

  it "rejects an unknown timezone identifier" do
    place = build(:place, time_zone: "Not/A_Timezone")

    expect(place).not_to be_valid
    expect(place.errors[:time_zone]).to be_present
  end

  it "allows a place without unresolved timezone metadata" do
    place = build(:place, time_zone: nil, time_zone_source: nil, time_zone_verified_at: nil)

    expect(place).to be_valid
  end

  it "returns a localized name and falls back to the canonical name" do
    place = create(:place, name: "London Heathrow Airport")
    create(:place_name, place: place, locale: "ru", name: "Аэропорт Хитроу")

    expect(place.name_for("ru")).to eq("Аэропорт Хитроу")
    expect(place.name_for("de")).to eq("London Heathrow Airport")
  end
end
