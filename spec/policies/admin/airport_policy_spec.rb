require "rails_helper"

RSpec.describe Admin::AirportPolicy, type: :policy do
  subject(:policy) { described_class.new(user, airport) }

  let(:airport) { build(:airport) }
  let(:user) { build(:user, role:) }
  let(:role) { "admin" }

  it "permits administrators to manage airports" do
    expect(policy.index?).to be(true)
    expect(policy.update?).to be(true)
    expect(policy.destroy?).to be(true)
  end

  context "when the user is a member" do
    let(:role) { "member" }

    it "denies every airport action" do
      expect(policy.index?).to be(false)
      expect(policy.update?).to be(false)
      expect(policy.destroy?).to be(false)
    end
  end

  context "when there is no user" do
    let(:user) { nil }

    it "denies every airport action" do
      expect(policy.index?).to be(false)
      expect(policy.update?).to be(false)
      expect(policy.destroy?).to be(false)
    end
  end
end
