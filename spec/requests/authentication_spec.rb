require "rails_helper"

RSpec.describe "Authentication", type: :request do
  def nested_keys(value)
    case value
    when Hash
      value.flat_map { |key, nested_value| [ key.to_s, *nested_keys(nested_value) ] }
    when Array
      value.flat_map { |nested_value| nested_keys(nested_value) }
    else
      []
    end
  end

  def sign_in_params(email: "user@example.com", password: "not-a-real-password-123")
    {
      session: {
        email:,
        password:
      }
    }
  end

  def sign_up_params(email: "new@example.com", password: "not-a-real-password-123", locale: "en")
    {
      registration: {
        email:,
        password:,
        password_confirmation: password,
        locale:
      }
    }
  end

  def set_session_cookie(raw_token)
    request = ActionDispatch::Request.new(Rails.application.env_config)
    jar = ActionDispatch::Cookies::CookieJar.build(request, {})
    jar.signed[:user_session_token] = raw_token

    cookies[:user_session_token] = jar[:user_session_token]
  end

  def set_cookie_header
    Array(response.headers["Set-Cookie"]).join("\n")
  end

  describe "GET /sign_in" do
    it "renders the sign-in page" do
      get sign_in_path

      expect(response).to have_http_status(:ok)
      expect(inertia.component).to eq("Auth/SignIn")
      expect(inertia.props.dig(:urls, :submit)).to eq(sign_in_path)
      expect(inertia.props.dig(:urls, :passwordReset)).to eq(new_password_reset_path)
      expect_inertia_runtime_document!
    end
  end

  describe "GET /sign_up" do
    it "renders the sign-up page" do
      get sign_up_path

      expect(response).to have_http_status(:ok)
      expect(inertia.component).to eq("Auth/SignUp")
      expect(inertia.props.dig(:urls, :submit)).to eq(sign_up_path)
      expect_inertia_runtime_document!
    end
  end

  describe "POST /sign_up" do
    it "registers the user, creates a session, redirects to dashboard, and sets the signed cookie" do
      expect { post sign_up_path, params: sign_up_params(email: " New@Example.COM ", locale: "ru") }
        .to change(User, :count).by(1)
        .and change(UserIdentity, :count).by(1)
        .and change(UserSession, :count).by(1)

      expect(response).to redirect_to(dashboard_path)
      expect(User.last).to have_attributes(primary_email: "new@example.com", locale: "ru")
      expect(response.cookies["user_session_token"]).to be_present
      expect(set_cookie_header).to match(/HttpOnly/i)
      expect(set_cookie_header).to match(/SameSite=Lax/i)
    end

    it "rejects invalid registration and keeps the visitor anonymous" do
      expect { post sign_up_path, params: sign_up_params(password: "too-short") }
        .not_to change { [ User.count, UserIdentity.count, UserSession.count ] }

      expect(response).to have_http_status(:unprocessable_content)
      expect(inertia.component).to eq("Auth/SignUp")
      expect(inertia.props[:formError]).to be_present
      expect(response.cookies["user_session_token"]).to be_blank
    end
  end

  describe "POST /sign_in" do
    let(:password) { "not-a-real-password-123" }
    let(:user) { create(:user, status:) }
    let(:status) { "active" }

    before do
      create(:user_identity, user:, email: "user@example.com", password:, password_confirmation: password)
    end

    it "signs in an active user with normalized email and sets the signed cookie" do
      expect { post sign_in_path, params: sign_in_params(email: " USER@example.com ", password:) }
        .to change(UserSession, :count).by(1)

      expect(response).to redirect_to(dashboard_path)
      expect(response.cookies["user_session_token"]).to be_present
      expect(set_cookie_header).to match(/HttpOnly/i)
      expect(set_cookie_header).to match(/SameSite=Lax/i)
    end

    it "rejects wrong passwords with a generic error" do
      expect { post sign_in_path, params: sign_in_params(password: "wrong-password-123") }
        .not_to change(UserSession, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(inertia.component).to eq("Auth/SignIn")
      expect(inertia.props[:formError]).to eq(I18n.t("auth.sessions.invalid"))
    end

    context "when the user is suspended" do
      let(:status) { "suspended" }

      it "uses the same generic error and does not create a session" do
        expect { post sign_in_path, params: sign_in_params(password:) }
          .not_to change(UserSession, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(inertia.props[:formError]).to eq(I18n.t("auth.sessions.invalid"))
      end
    end
  end

  describe "DELETE /sign_out" do
    let(:raw_token) { SecureRandom.urlsafe_base64(48) }
    let!(:user_session) { create(:user_session, token_digest: UserSession.digest_token(raw_token)) }

    before do
      set_session_cookie(raw_token)
    end

    it "revokes the current user session and clears the cookie" do
      expect { delete sign_out_path }.to change { user_session.reload.revoked_at }.from(nil)

      expect(response).to redirect_to(sign_in_path)
      expect(set_cookie_header).to include("user_session_token=;")
    end
  end

  describe "GET /dashboard" do
    it "redirects anonymous users to sign in" do
      get dashboard_path

      expect(response).to redirect_to(sign_in_path)
    end

    context "with a valid user-session cookie" do
      let(:raw_token) { SecureRandom.urlsafe_base64(48) }
      let!(:user_session) do
        create(
          :user_session,
          token_digest: UserSession.digest_token(raw_token),
          last_seen_at:
        )
      end
      let(:last_seen_at) { 5.minutes.ago }

      before do
        set_session_cookie(raw_token)
      end

      it "renders a protected dashboard without exposing auth internals" do
        get dashboard_path

        expect(response).to have_http_status(:ok)
        expect(inertia.component).to eq("Dashboard/Show")
        expect(inertia.props.dig(:copy, :email)).to eq(user_session.user.primary_email)
        expect(nested_keys(inertia.props)).not_to include(*sensitive_prop_keys)
      end

      it "does not update recent last_seen_at values" do
        freeze_time do
          get dashboard_path

          expect(user_session.reload.last_seen_at.to_i).to eq(last_seen_at.to_i)
        end
      end

      it "updates stale last_seen_at values" do
        user_session.update!(last_seen_at: 11.minutes.ago)

        freeze_time do
          get dashboard_path

          expect(user_session.reload.last_seen_at).to eq(Time.current)
        end
      end
    end

    it "clears revoked sessions and treats the request as anonymous" do
      raw_token = SecureRandom.urlsafe_base64(48)
      create(:user_session, token_digest: UserSession.digest_token(raw_token), revoked_at: 1.minute.ago)
      set_session_cookie(raw_token)

      get dashboard_path

      expect(response).to redirect_to(sign_in_path)
      expect(set_cookie_header).to include("user_session_token=;")
    end

    it "clears suspended user sessions and treats the request as anonymous" do
      raw_token = SecureRandom.urlsafe_base64(48)
      user = create(:user, status: "suspended")
      user_identity = create(:user_identity, user:)
      create(:user_session, user:, user_identity:, token_digest: UserSession.digest_token(raw_token))
      set_session_cookie(raw_token)

      get dashboard_path

      expect(response).to redirect_to(sign_in_path)
      expect(set_cookie_header).to include("user_session_token=;")
    end
  end
end
