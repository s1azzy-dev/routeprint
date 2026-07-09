require "rails_helper"

RSpec.describe "Password resets", type: :request do
  def password_reset_params(email: "user@example.com")
    {
      password_reset: {
        email:
      }
    }
  end

  def password_reset_update_params(password: "new-password-123", password_confirmation: password)
    {
      password_reset: {
        password:,
        password_confirmation:
      }
    }
  end

  describe "GET /password-reset/new" do
    it "renders the reset request form without exposing auth internals" do
      get new_password_reset_path

      expect(response).to have_http_status(:ok)
      expect(inertia.component).to eq("PasswordResets/New")
      expect(inertia.props.dig(:urls, :submit)).to eq(password_reset_path)
      expect(inertia.props.dig(:urls, :signIn)).to eq(sign_in_path)
      expect(inertia.props.dig(:copy, :heading)).to be_present
      expect_inertia_runtime_document!
    end
  end

  describe "POST /password-reset" do
    it "stores a digest-backed token, sends email, and redirects with generic success for existing accounts" do
      user_identity = create(:user_identity, email: " user@example.com ")

      freeze_time do
        expect { post password_reset_path, params: password_reset_params(email: " USER@example.com ") }
          .to change(ActionMailer::Base.deliveries, :count).by(1)

        expect(user_identity.reload.password_reset_token_digest).to be_present
        expect(user_identity.password_reset_sent_at).to eq(Time.current)
        expect(ActionMailer::Base.deliveries.last.body.encoded).not_to include(user_identity.password_reset_token_digest)
      end

      expect(response).to redirect_to(sign_in_path)
      expect(flash[:notice]).to eq(I18n.t("auth.password_resets.requested"))
    end

    it "returns the same generic success for unknown accounts without sending email" do
      expect { post password_reset_path, params: password_reset_params(email: "missing@example.com") }
        .not_to change(ActionMailer::Base.deliveries, :count)

      expect(response).to redirect_to(sign_in_path)
      expect(flash[:notice]).to eq(I18n.t("auth.password_resets.requested"))
    end
  end

  describe "GET /password-reset/:token" do
    it "renders the reset consume form" do
      get edit_password_reset_token_path("raw-token")

      expect(response).to have_http_status(:ok)
      expect(inertia.component).to eq("PasswordResets/Edit")
      expect(inertia.props.dig(:urls, :signIn)).to eq(sign_in_path)
      expect(inertia.props.to_s).not_to include("raw-token")
      expect_inertia_runtime_document!
    end
  end

  describe "PATCH /password-reset/:token" do
    let(:raw_token) { UserIdentity.generate_token }
    let!(:user_identity) do
      create(
        :user_identity,
        password_reset_token_digest: UserIdentity.digest_token(raw_token),
        password_reset_sent_at: 5.minutes.ago
      )
    end

    before do
      create(:user_session, user: user_identity.user, user_identity:)
      create(:user_session, user: user_identity.user, user_identity:)
    end

    it "updates the password, clears reset fields, revokes active sessions, and redirects to sign in" do
      expect do
        patch password_reset_token_path(raw_token), params: password_reset_update_params
      end.to change { UserSession.active.where(user: user_identity.user).count }.from(2).to(0)

      expect(response).to redirect_to(sign_in_path)
      expect(flash[:notice]).to eq(I18n.t("auth.password_resets.updated"))
      expect(user_identity.reload.authenticate("new-password-123")).to eq(user_identity)
      expect(user_identity.password_reset_token_digest).to be_nil
      expect(user_identity.password_reset_sent_at).to be_nil
    end

    it "rejects invalid tokens with a generic response" do
      expect do
        patch password_reset_token_path("invalid-token"), params: password_reset_update_params
      end.not_to change { UserSession.active.where(user: user_identity.user).count }

      expect(response).to have_http_status(:unprocessable_content)
      expect(inertia.component).to eq("PasswordResets/Edit")
      expect(inertia.props[:formError]).to eq(I18n.t("auth.password_resets.invalid"))
    end

    it "rejects expired tokens without changing the password" do
      user_identity.update!(password_reset_sent_at: 31.minutes.ago)

      patch password_reset_token_path(raw_token), params: password_reset_update_params

      expect(response).to have_http_status(:unprocessable_content)
      expect(inertia.props[:formError]).to eq(I18n.t("auth.password_resets.invalid"))
      expect(user_identity.reload.authenticate("new-password-123")).to be_falsey
    end

    it "rejects passwords that do not meet policy" do
      patch password_reset_token_path(raw_token), params: password_reset_update_params(password: "short")

      expect(response).to have_http_status(:unprocessable_content)
      expect(inertia.props[:formError]).to eq(I18n.t("auth.password_resets.invalid"))
    end
  end
end
