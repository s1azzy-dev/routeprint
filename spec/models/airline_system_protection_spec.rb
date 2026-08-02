require "rails_helper"

RSpec.describe "Protected unknown airline", type: :model do
  subject(:airline) { create(:airline, :system_placeholder) }

  it "rejects ordinary edits and lifecycle changes" do
    expect(airline.update(name: "Changed", review_status: "rejected")).to be(false)
    expect(airline.reload).to have_attributes(name: "Unknown airline", review_status: "approved")
  end

  it "rejects merging the system airline" do
    target = create(:airline, :approved)

    expect(airline.update(review_status: "merged", merged_into: target)).to be(false)
    expect(airline.reload).to have_attributes(review_status: "approved", merged_into: nil)
  end

  it "rejects deletion" do
    expect(airline.destroy).to be(false)
    expect(airline).not_to be_destroyed
    expect(Airline.find(airline.id)).to eq(airline)
  end

  it "rejects catalog evidence and import links" do
    source_record = create(:imports_source_record)

    expect(build(:airline_designator, airline:)).not_to be_valid
    expect(build(:airline_submission, airline:)).not_to be_valid
    expect(build(:imports_airline_source_link, airline:, source_record:)).not_to be_valid
  end
end
