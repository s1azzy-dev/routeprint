require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:user_identities).dependent(:destroy) }
    it { is_expected.to have_many(:user_sessions).dependent(:destroy) }
  end

  describe "validations" do
    subject(:user) { build(:user) }

    it { is_expected.to validate_presence_of(:primary_email) }
    it { is_expected.to validate_uniqueness_of(:primary_email).case_insensitive }
    it { is_expected.to validate_inclusion_of(:role).in_array(described_class::ROLES) }
    it { is_expected.to validate_inclusion_of(:status).in_array(described_class::STATUSES) }
    it { is_expected.to validate_inclusion_of(:locale).in_array(I18n.available_locales.map(&:to_s)) }
  end

  it "normalizes primary_email before validation" do
    user = build(:user, primary_email: "  USER@Example.COM ")

    user.validate

    expect(user.primary_email).to eq("user@example.com")
  end

  it "normalizes blank display names to nil" do
    user = build(:user, display_name: "   ")

    user.validate

    expect(user.display_name).to be_nil
  end

  it "enforces uniqueness of normalized primary_email" do
    create(:user, primary_email: "user@example.com")

    duplicate = build(:user, primary_email: " USER@example.com ")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:primary_email]).to include("has already been taken")
  end

  it "treats active users as active and not suspended" do
    user = build(:user, status: "active")

    expect(user).to be_active
    expect(user).not_to be_suspended
  end

  it "treats suspended users as suspended and not active" do
    user = build(:user, status: "suspended")

    expect(user).to be_suspended
    expect(user).not_to be_active
  end

  it "identifies admins" do
    expect(build(:user, role: "admin")).to be_admin
  end
end
