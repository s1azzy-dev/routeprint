class SessionsController < ApplicationController
  before_action :redirect_authenticated_user, only: %i[new create]
  before_action :require_authentication, only: :destroy

  def new
    render inertia: "Auth/SignIn", props: sign_in_props
  end

  def create
    result = Auth::AuthenticateUser.call(input: session_params)

    if result.success?
      issue_user_session_for!(result.value![:user], result.value![:user_identity])
      redirect_to dashboard_path, notice: t("auth.sessions.created")
    else
      render inertia: "Auth/SignIn",
        props: sign_in_props(form_error: t("auth.sessions.invalid")),
        status: :unprocessable_content
    end
  end

  def destroy
    Auth::LogoutUser.call(input: { user_session: current_user_session })
    clear_current_user_session!
    redirect_to sign_in_path, notice: t("auth.sessions.destroyed"), status: :see_other
  end

  private

  def session_params
    params.require(:session).permit(:email, :password).to_h.symbolize_keys
  end

  def sign_in_props(form_error: nil)
    {
      copy: {
        email: t("auth.fields.email"),
        heading: t("auth.sessions.heading"),
        password: t("auth.fields.password"),
        passwordReset: t("auth.sessions.password_reset"),
        submit: t("auth.sessions.submit"),
        switchLink: t("auth.sessions.sign_up_link"),
        switchPrompt: t("auth.sessions.sign_up_prompt")
      },
      formError: form_error,
      urls: {
        passwordReset: new_password_reset_path,
        signUp: sign_up_path,
        submit: sign_in_path
      },
      values: {
        email: params.dig(:session, :email)&.strip&.downcase
      }
    }
  end

  def redirect_authenticated_user
    redirect_to dashboard_path if authenticated?
  end
end
