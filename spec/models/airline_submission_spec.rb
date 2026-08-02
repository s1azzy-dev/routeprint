require "rails_helper"

RSpec.describe AirlineSubmission, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:airline) }
    it { is_expected.to belong_to(:submitted_by_user).class_name("User").optional }
    it { is_expected.to belong_to(:submitted_country).class_name("Country").optional }
  end

  describe "validations" do
    subject(:submission) { build(:airline_submission) }

    it { is_expected.to validate_presence_of(:submitted_name) }
  end

  it "normalizes preserved submission evidence" do
    submission = build(:airline_submission, submitted_name: "  Example   Air ", submitted_code: " ab ")

    submission.validate

    expect(submission).to have_attributes(submitted_name: "Example Air", submitted_code: "AB")
  end
end
