module Auth
  # Starts a password reset flow without revealing whether an email exists.
  #
  # @example
  #   Auth::RequestPasswordReset.call(input: { email: "person@example.com" })
  # @param input [Hash] the email address requesting a reset
  class RequestPasswordReset < ApplicationInteractor
    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:email).filled(:string)
      end
    end

    def call
      user_identity = UserIdentity.password.find_by(email: EmailNormalizer.normalize(input[:email]))
      yield issue_reset(user_identity) if user_identity

      Success()
    end

    private

    def issue_reset(user_identity)
      token = UserIdentity.generate_token
      user_identity.assign_attributes(
        password_reset_token_digest: UserIdentity.digest_token(token),
        password_reset_sent_at: Time.current
      )

      return send_email(user_identity, token) if user_identity.save

      fail_with(code: :validation_error, errors: user_identity.errors.to_hash)
    end

    def send_email(user_identity, token)
      result = safe_call { AuthMailer.password_reset(user_identity:, token:).deliver_now }
      return Success() if result.success?

      result.or { |error| fail_with(code: :delivery_failed, errors: { email: [ error.message ] }) }
    end
  end
end
