require "rails_helper"

RSpec.describe UserIdentity, type: :model do
  subject(:user_identity) { build(:user_identity) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:user_sessions).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to validate_inclusion_of(:provider).in_array(Auth::Constants::PROVIDERS) }
    it { is_expected.to validate_uniqueness_of(:password_reset_token_digest).allow_nil }
  end

  it "normalizes provider and email before validation" do
    user_identity = build(:user_identity, provider: " Password ", email: " USER@Example.COM ")

    user_identity.validate

    expect(user_identity.provider).to eq(Auth::Constants::PASSWORD)
    expect(user_identity.email).to eq("user@example.com")
  end

  it "stores password identities with password digests only" do
    user_identity = create(
      :user_identity,
      password: "not-a-real-password-123",
      password_confirmation: "not-a-real-password-123"
    )

    expect(user_identity.password_digest).to be_present
    expect(user_identity.password_digest).not_to include("not-a-real-password-123")
    expect(user_identity.authenticate("not-a-real-password-123")).to eq(user_identity)
  end

  it "rejects passwords shorter than 12 characters" do
    user_identity = build(:user_identity, password: "short-test", password_confirmation: "short-test")

    expect(user_identity).not_to be_valid
    expect(user_identity.errors[:password]).to include("is too short (minimum is 12 characters)")
  end

  it "requires password confirmation when setting a password" do
    user_identity = build(:user_identity, password_confirmation: nil)

    expect(user_identity).not_to be_valid
    expect(user_identity.errors[:password_confirmation]).to include("can't be blank")
  end

  it "requires password_digest for password identities" do
    user_identity = build(:user_identity, password: nil, password_confirmation: nil, password_digest: nil)

    expect(user_identity).not_to be_valid
    expect(user_identity.errors[:password_digest]).to include("can't be blank")
  end

  it "requires provider_uid for external identities" do
    user_identity = build(:user_identity, :google, provider_uid: nil)

    expect(user_identity).not_to be_valid
    expect(user_identity.errors[:provider_uid]).to include("can't be blank")
  end

  it "prevents duplicate provider_uid within the same provider" do
    create(:user_identity, :google, provider_uid: "google-123")

    user_identity = build(:user_identity, :google, provider_uid: "google-123")

    expect(user_identity).not_to be_valid
    expect(user_identity.errors[:provider_uid]).to include("has already been taken")
  end

  it "allows one password identity per user" do
    user = create(:user)
    create(:user_identity, user:)

    duplicate = build(:user_identity, user:)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:user_id]).to include("already has a password identity")
  end

  describe ".generate_token" do
    it "generates high entropy url-safe tokens" do
      token = described_class.generate_token

      expect(token).to match(/\A[A-Za-z0-9\-_]+\z/)
      expect(token.length).to be >= 64
    end
  end

  describe ".find_by_password_reset_token" do
    it "finds identities by digesting the raw token" do
      token = described_class.generate_token
      user_identity = create(:user_identity, password_reset_token_digest: described_class.digest_token(token))

      expect(described_class.find_by_password_reset_token(token)).to eq(user_identity)
    end
  end

  describe "#password_reset_expired?" do
    around { |example| freeze_time(&example) }

    it "is expired when the timestamp is blank" do
      expect(build(:user_identity, password_reset_sent_at: nil)).to be_password_reset_expired
    end

    it "is not expired inside the reset ttl" do
      expect(build(:user_identity, password_reset_sent_at: 10.minutes.ago)).not_to be_password_reset_expired
    end

    it "is expired outside the reset ttl" do
      expect(build(:user_identity, password_reset_sent_at: 31.minutes.ago)).to be_password_reset_expired
    end
  end
end
