module Auth
  class LogoutUser < ApplicationInteractor
    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:user_session).filled(type?: UserSession)
      end
    end

    def call
      user_session = input[:user_session]
      yield revoke_user_session(user_session)

      Success(user_session:)
    end

    private

    def revoke_user_session(user_session)
      return Success(user_session) if user_session.revoked?

      safe_call { user_session.revoke! }
        .or { |error| fail_with(code: :logout_failed, errors: { user_session: [ error.message ] }) }
    end
  end
end
