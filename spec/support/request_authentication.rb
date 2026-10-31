module RequestAuthentication
  def authenticate_member(user)
    raw = SecureRandom.urlsafe_base64(48)
    create(:user_session, user:, token_digest: UserSession.digest_token(raw))
    request = ActionDispatch::Request.new(Rails.application.env_config)
    jar = ActionDispatch::Cookies::CookieJar.build(request, {})
    jar.signed[:user_session_token] = raw
    cookies[:user_session_token] = jar[:user_session_token]
  end
end

RSpec.configure { |config| config.include RequestAuthentication, type: :request }
