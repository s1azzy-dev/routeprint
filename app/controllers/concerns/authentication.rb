module Authentication
  extend ActiveSupport::Concern

  USER_SESSION_COOKIE_KEY = :user_session_token

  included do
    before_action :resume_user_session
    helper_method :authenticated?, :current_user, :current_user_session
  end

  private

  def authenticated?
    current_user.present?
  end

  def current_user
    Current.user
  end

  def current_user_session
    Current.user_session
  end

  def require_authentication
    return if authenticated?

    redirect_to sign_in_path, alert: t("auth.sessions.require_authentication")
  end

  def start_user_session!(user_session, token)
    cookies.signed[USER_SESSION_COOKIE_KEY] = {
      value: token,
      expires: user_session.expires_at,
      httponly: true,
      same_site: :lax,
      secure: Rails.env.production?
    }

    Current.user_session = user_session
    Current.user = user_session.user
  end

  def clear_current_user_session!
    Current.reset
    cookies.delete(USER_SESSION_COOKIE_KEY, same_site: :lax, secure: Rails.env.production?)
  end

  def issue_user_session_for!(user, user_identity)
    result = Auth::IssueSession.call(
      input: {
        user:,
        user_identity:,
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      }
    )

    user_session = result.value![:user_session]
    token = result.value![:token]
    start_user_session!(user_session, token)
  end

  def resume_user_session
    Current.reset

    token = cookies.signed[USER_SESSION_COOKIE_KEY]
    return if token.blank?

    user_session = UserSession.active.find_by_token(token)
    return clear_current_user_session! unless user_session&.user&.active?

    Current.user_session = user_session
    Current.user = user_session.user
    user_session.touch_last_seen_if_stale!
  end
end
