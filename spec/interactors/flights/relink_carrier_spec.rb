require "rails_helper"

RSpec.describe Flights::RelinkCarrier do
  let(:source) { create(:airline) }
  let(:target) { create(:airline, :approved) }
  let(:actor) { create(:user, role: "admin") }
  let!(:flight) { create(:travel_segment) }

  before do
    flight.flight_detail.update!(marketing_airline: source, operating_airline: source, marketing_designator: "OLD")
  end

  def relink
    described_class.call(input: { actor:, source:, target: })
  end

  it "relinks both roles and preserves observed historical evidence" do
    expect(relink).to be_success
    expect(flight.reload.flight_detail).to have_attributes(marketing_airline_id: target.id,
      operating_airline_id: target.id, marketing_designator: "OLD")
    expect(source.reload.review_status).to eq("pending")
  end

  it "participates in an outer moderation transaction rollback" do
    Airline.transaction do
      expect(relink).to be_success
      raise ActiveRecord::Rollback
    end
    expect(flight.reload.flight_detail.marketing_airline_id).to eq(source.id)
    expect(flight.flight_detail.operating_airline_id).to eq(source.id)
  end

  it "rejects an unapproved target without changes" do
    target.update!(review_status: "rejected")
    expect(relink).to be_failure
    expect(flight.reload.flight_detail.marketing_airline_id).to eq(source.id)
  end

  it "rejects a nonadmin caller" do
    actor.update!(role: "member")
    expect(relink).to be_failure
  end
end
