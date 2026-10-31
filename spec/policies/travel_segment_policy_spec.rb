require "rails_helper"

RSpec.describe TravelSegmentPolicy do
  let(:owner) { create(:user) }
  let(:flight) { build(:travel_segment, user: owner) }

  it "grants only the active owner access to owned records" do
    expect(described_class.new(owner, flight).update?).to be(true)
    expect(described_class.new(create(:user, role: "admin"), flight).show?).to be(false)
    expect(described_class.new(nil, flight).destroy?).to be(false)
    owner.status = "suspended"
    expect(described_class.new(owner, flight).show?).to be(false)
  end

  it "restricts the scope to the authenticated owner" do
    mine = create(:travel_segment, user: owner)
    create(:travel_segment)
    expect(described_class::Scope.new(owner, TravelSegment).resolve).to contain_exactly(mine)
    expect(described_class::Scope.new(nil, TravelSegment).resolve).to be_empty
  end
end
