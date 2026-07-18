require "rails_helper"

RSpec.describe CountryName, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:country) }
  end

  describe "validations" do
    subject(:country_name) { build(:country_name) }

    it { is_expected.to validate_presence_of(:locale) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:locale).scoped_to(:country_id).case_insensitive }
  end

  it "normalizes locale and name" do
    country_name = build(:country_name, locale: " RU ", name: "  Германия  ")

    country_name.validate

    expect(country_name.locale).to eq("ru")
    expect(country_name.name).to eq("Германия")
  end
end
