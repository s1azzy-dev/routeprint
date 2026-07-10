require "rails_helper"

RSpec.describe PlaceName, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:place) }
  end

  describe "validations" do
    subject(:place_name) { build(:place_name) }

    it { is_expected.to validate_presence_of(:locale) }
    it { is_expected.to validate_inclusion_of(:locale).in_array(I18n.available_locales.map(&:to_s)) }
    it { is_expected.to validate_presence_of(:name) }

    it {
      expect(place_name).to validate_uniqueness_of(:locale)
        .scoped_to(:place_id)
        .ignoring_case_sensitivity
    }
  end

  it "normalizes the locale and name" do
    place_name = build(:place_name, locale: " RU ", name: "  Аэропорт  ")

    place_name.validate

    expect(place_name.locale).to eq("ru")
    expect(place_name.name).to eq("Аэропорт")
  end
end
