module Auth
  class IssueSession < ApplicationInteractor
    SESSION_TTL = 30.days

    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:user).filled(type?: User)
        required(:user_identity).filled(type?: UserIdentity)
      end
    end

    def call
      token = SecureRandom.urlsafe_base64(48)
      user_session = yield create_user_session(token)

      Success(user_session:, token:)
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    private

    def create_user_session(token)
      now = Time.current
      user_session = UserSession.new(
        user: input[:user],
        user_identity: input[:user_identity],
        authentication_method: input[:user_identity].provider,
        token_digest: UserSession.digest_token(token),
        ip_address: input[:ip_address],
        user_agent: input[:user_agent],
        last_seen_at: now,
        expires_at: now + SESSION_TTL
      )

      return Success(user_session) if user_session.save

      fail_with(code: :validation_error, errors: user_session.errors.to_hash)
    end
  end
end
