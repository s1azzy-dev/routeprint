require "rails_helper"

RSpec.describe UserSession, type: :model do
  subject(:user_session) { build(:user_session) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:user_identity) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:authentication_method) }
    it { is_expected.to validate_inclusion_of(:authentication_method).in_array(Auth::Constants::PROVIDERS) }
    it { is_expected.to validate_presence_of(:token_digest) }
    it { is_expected.to validate_uniqueness_of(:token_digest) }
    it { is_expected.to validate_presence_of(:last_seen_at) }
    it { is_expected.to validate_presence_of(:expires_at) }
  end

  it "is active when not revoked and not expired" do
    expect(build(:user_session)).to be_active
  end

  it "is not active when revoked" do
    user_session = build(:user_session, revoked_at: Time.current)

    expect(user_session).not_to be_active
    expect(user_session).to be_revoked
  end

  it "is not active when expired" do
    user_session = build(:user_session, expires_at: 1.minute.ago)

    expect(user_session).not_to be_active
    expect(user_session).to be_expired
  end

  it "revokes sessions" do
    user_session = create(:user_session)

    expect { user_session.revoke! }.to change { user_session.reload.revoked_at }.from(nil)
  end

  describe ".find_by_token" do
    it "finds sessions by digesting the raw token" do
      raw_token = SecureRandom.urlsafe_base64(48)
      user_session = create(:user_session, token_digest: described_class.digest_token(raw_token))

      expect(described_class.find_by_token(raw_token)).to eq(user_session)
    end
  end

  describe "#touch_last_seen_if_stale!" do
    around { |example| freeze_time(&example) }

    it "does not update last_seen_at inside the touch interval" do
      user_session = create(:user_session, last_seen_at: 5.minutes.ago)

      expect { user_session.touch_last_seen_if_stale! }.not_to change { user_session.reload.last_seen_at }
    end

    it "updates last_seen_at outside the touch interval" do
      user_session = create(:user_session, last_seen_at: 11.minutes.ago)

      expect { user_session.touch_last_seen_if_stale! }.to change { user_session.reload.last_seen_at }.to(Time.current)
    end
  end
end
