require "rails_helper"

RSpec.describe Airline, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:country).optional }
    it { is_expected.to belong_to(:merged_into).class_name("Airline").optional }
    it { is_expected.to belong_to(:reviewed_by).class_name("User").optional }
    it { is_expected.to have_many(:designators).class_name("AirlineDesignator").dependent(:restrict_with_exception) }
    it { is_expected.to have_one(:submission).class_name("AirlineSubmission").dependent(:restrict_with_exception) }
    it { is_expected.to have_many(:source_links).class_name("Imports::AirlineSourceLink").dependent(:restrict_with_exception) }
  end

  describe "validations" do
    subject(:airline) { build(:airline) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_inclusion_of(:review_status).in_array(%w[pending approved rejected merged]) }
    it { is_expected.to validate_inclusion_of(:operational_status).in_array(%w[active inactive unknown]) }
    it { is_expected.to validate_inclusion_of(:record_kind).in_array(%w[catalog system_placeholder]) }
  end

  it "normalizes the canonical name" do
    airline = build(:airline, name: "  Example   Air  ")

    airline.validate

    expect(airline).to have_attributes(name: "Example Air", normalized_name: "example air")
  end

  it "normalizes lifecycle values" do
    airline = build(:airline, review_status: " APPROVED ", operational_status: " ACTIVE ", record_kind: " CATALOG ")

    airline.validate

    expect(airline).to have_attributes(review_status: "approved", operational_status: "active", record_kind: "catalog")
  end

  it "keeps review and real-world operation independent" do
    historical = build(:airline, :approved, :inactive)

    expect(historical).to be_valid
  end

  it "requires a merge target only for merged records" do
    target = create(:airline, :approved)

    expect(build(:airline, review_status: "merged", merged_into: target)).to be_valid
    expect(build(:airline, review_status: "merged", merged_into: nil)).not_to be_valid
    expect(build(:airline, review_status: "pending", merged_into: target)).not_to be_valid
  end

  it "rejects self-merge and non-approved merge targets" do
    airline = build(:airline, review_status: "merged")
    airline.merged_into = airline

    expect(airline).not_to be_valid
    expect(build(:airline, review_status: "merged", merged_into: build(:airline))).not_to be_valid
  end
end
