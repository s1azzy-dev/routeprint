require "rails_helper"

RSpec.describe Countries::BackfillPlaces, type: :interactor do
  it "links matching legacy place codes and reports unmatched codes" do
    country = create(:country, code: "GB")
    matching_place = create(:place, country_code: "GB")
    unmatched_place = create(:place, country_code: "ZZ")

    result = described_class.call

    expect(result).to be_success
    expect(result.value!).to include(matched_count: 1, unmatched_codes: [ "ZZ" ])
    expect(matching_place.reload.country).to eq(country)
    expect(unmatched_place.reload.country).to be_nil
  end
end
