require "rails_helper"

RSpec.describe Auth::ResetPassword, type: :interactor do
  subject(:result) { described_class.call(input:) }

  let(:input) do
    {
      token:,
      password: "new-password-123",
      password_confirmation:
    }
  end
  let(:password_confirmation) { "new-password-123" }
  let(:stored_token) { UserIdentity.generate_token }
  let(:token) { stored_token }
  let!(:user_identity) do
    create(
      :user_identity,
      password_reset_token_digest: UserIdentity.digest_token(stored_token),
      password_reset_sent_at: 5.minutes.ago
    )
  end

  around { |example| freeze_time(&example) }

  before do
    create(:user_session, user: user_identity.user, user_identity:)
    create(:user_session, user: user_identity.user, user_identity:)
  end

  it "updates the password, clears reset fields, and revokes active sessions" do
    expect { result }.to change { UserSession.active.where(user: user_identity.user).count }.from(2).to(0)

    expect(result).to be_success
    expect(user_identity.reload.authenticate("new-password-123")).to eq(user_identity)
    expect(user_identity.password_reset_token_digest).to be_nil
    expect(user_identity.password_reset_sent_at).to be_nil
  end

  context "when the token is invalid" do
    let(:token) { "invalid-token" }

    it "fails without revoking sessions" do
      expect { result }.not_to change { UserSession.active.where(user: user_identity.user).count }

      expect(result).to be_failure
      expect(result.failure[:code]).to eq(:invalid_token)
    end
  end

  context "when the token is expired" do
    before do
      user_identity.update!(password_reset_sent_at: 31.minutes.ago)
    end

    it "fails without changing the password" do
      expect(result).to be_failure
      expect(result.failure[:code]).to eq(:invalid_token)
      expect(user_identity.reload.authenticate("new-password-123")).to be_falsey
    end
  end

  context "when the password is invalid" do
    let(:password_confirmation) { "mismatch-password-123" }

    it "fails without revoking sessions" do
      expect { result }.not_to change { UserSession.active.where(user: user_identity.user).count }

      expect(result).to be_failure
      expect(result.failure[:code]).to eq(:validation_error)
    end
  end
end
