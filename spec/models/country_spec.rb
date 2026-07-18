require "rails_helper"

RSpec.describe Country, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:country_names).dependent(:destroy) }
    it { is_expected.to have_many(:places).dependent(:restrict_with_exception) }
  end

  describe "validations" do
    subject(:country) { build(:country) }

    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_uniqueness_of(:code).case_insensitive }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:continent_code) }
  end

  it "normalizes its code and returns localized names with fallback" do
    country = create(:country, code: " gb ", name: "United Kingdom")
    create(:country_name, country:, locale: "ru", name: "Великобритания")

    country.validate

    expect(country.code).to eq("GB")
    expect(country.name_for("ru")).to eq("Великобритания")
    expect(country.name_for("de")).to eq("United Kingdom")
  end

  it "accepts the airport-compatible XK territory code" do
    expect(build(:country, code: "XK")).to be_valid
  end
end
