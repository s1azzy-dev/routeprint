module Auth
  class RegisterUser < ApplicationInteractor
    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:email).filled(:string)
        required(:password).filled(:string)
        required(:password_confirmation).filled(:string)
        optional(:locale).filled(:string)
      end
    end

    def call
      in_transaction do
        user = yield create_user
        user_identity = yield create_password_identity(user)

        Success(user:, user_identity:)
      end
    end

    private

    def create_user
      user = User.new(
        primary_email: input[:email],
        locale: input[:locale].presence || I18n.default_locale.to_s
      )

      return Success(user) if user.save

      fail_with(code: :validation_error, errors: user.errors.to_hash)
    end

    def create_password_identity(user)
      user_identity = user.user_identities.new(
        provider: Auth::Constants::PASSWORD,
        email: input[:email],
        password: input[:password],
        password_confirmation: input[:password_confirmation]
      )

      return Success(user_identity) if user_identity.save

      fail_with(code: :validation_error, errors: user_identity.errors.to_hash)
    end
  end
end
