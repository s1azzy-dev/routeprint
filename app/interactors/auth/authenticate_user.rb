module Auth
  # Authenticates a password identity and verifies that its user is active.
  #
  # @example
  #   Auth::AuthenticateUser.call(input: { email: "person@example.com", password: "secret" })
  # @param input [Hash] email and password credentials
  class AuthenticateUser < ApplicationInteractor
    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:email).filled(:string)
        required(:password).filled(:string)
      end
    end

    def call
      user_identity = yield find_password_identity
      yield authenticate_password(user_identity)
      yield ensure_active_user(user_identity.user)

      Success(user: user_identity.user, user_identity:)
    end

    private

    def find_password_identity
      user_identity = UserIdentity.password.find_by(email: EmailNormalizer.normalize(input[:email]))
      return Success(user_identity) if user_identity

      invalid_credentials
    end

    def authenticate_password(user_identity)
      return Success(user_identity) if user_identity.authenticate(input[:password])

      invalid_credentials
    end

    def ensure_active_user(user)
      return Success(user) if user.active?

      invalid_credentials
    end

    def invalid_credentials
      fail_with(code: :invalid_credentials)
    end
  end
end
