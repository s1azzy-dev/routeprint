class RegistrationsController < ApplicationController
  before_action :redirect_authenticated_user, only: %i[new create]

  def new
    render inertia: "Auth/SignUp", props: sign_up_props
  end

  def create
    result = Auth::RegisterUser.call(input: registration_params)

    if result.success?
      issue_user_session_for!(result.value![:user], result.value![:user_identity])
      redirect_to dashboard_path, notice: t("auth.registrations.created")
    else
      render inertia: "Auth/SignUp",
        props: sign_up_props(form_error: registration_error_message(result.failure[:errors])),
        status: :unprocessable_content
    end
  end

  private

  def registration_params
    params.require(:registration).permit(:email, :password, :password_confirmation, :locale).to_h.symbolize_keys
  end

  def sign_up_props(form_error: nil)
    {
      copy: {
        email: t("auth.fields.email"),
        heading: t("auth.registrations.heading"),
        locale: t("auth.fields.locale"),
        password: t("auth.fields.password"),
        passwordConfirmation: t("auth.fields.password_confirmation"),
        submit: t("auth.registrations.submit"),
        switchLink: t("auth.registrations.sign_in_link"),
        switchPrompt: t("auth.registrations.sign_in_prompt")
      },
      formError: form_error,
      localeOptions: I18n.available_locales.map do |locale|
        { label: t("auth.locales.#{locale}"), value: locale.to_s }
      end,
      urls: {
        signIn: sign_in_path,
        submit: sign_up_path
      },
      values: {
        email: params.dig(:registration, :email)&.strip&.downcase,
        locale: selected_locale
      }
    }
  end

  def registration_error_message(errors)
    errors.to_h.values.flatten.to_sentence.presence || t("auth.registrations.invalid")
  end

  def selected_locale
    locale = params.dig(:registration, :locale).presence || I18n.default_locale.to_s
    return locale if I18n.available_locales.map(&:to_s).include?(locale)

    I18n.default_locale.to_s
  end

  def redirect_authenticated_user
    redirect_to dashboard_path if authenticated?
  end
end
