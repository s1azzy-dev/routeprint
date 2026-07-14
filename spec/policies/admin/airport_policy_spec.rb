require "rails_helper"

RSpec.describe Admin::AirportPolicy, type: :policy do
  subject(:policy) { described_class.new(user, airport) }

  let(:airport) { build(:airport) }
  let(:user) { build(:user, role:) }
  let(:role) { "admin" }

  it "permits administrators to manage airports" do
    expect(policy).to be_index
    expect(policy).to be_update
    expect(policy).to be_destroy
  end

  context "when the user is a member" do
    let(:role) { "member" }

    it "denies every airport action" do
      expect(policy).not_to be_index
      expect(policy).not_to be_update
      expect(policy).not_to be_destroy
    end
  end

  context "when there is no user" do
    let(:user) { nil }

    it "denies every airport action" do
      expect(policy).not_to be_index
      expect(policy).not_to be_update
      expect(policy).not_to be_destroy
    end
  end
end
