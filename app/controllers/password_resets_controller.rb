class PasswordResetsController < ApplicationController
  before_action :redirect_authenticated_user, only: %i[new create]

  def new
    render inertia: "PasswordResets/New", props: new_props
  end

  def create
    Auth::RequestPasswordReset.call(input: password_reset_params)

    redirect_to sign_in_path, notice: t("auth.password_resets.requested")
  end

  def edit
    render inertia: "PasswordResets/Edit", props: edit_props
  end

  def update
    result = Auth::ResetPassword.call(input: password_reset_update_params.merge(token: params[:token]))

    if result.success?
      redirect_to sign_in_path, notice: t("auth.password_resets.updated"), status: :see_other
    else
      render inertia: "PasswordResets/Edit",
        props: edit_props(form_error: t("auth.password_resets.invalid")),
        status: :unprocessable_content
    end
  end

  private

  def password_reset_params
    params.require(:password_reset).permit(:email).to_h.symbolize_keys
  end

  def password_reset_update_params
    params.require(:password_reset).permit(:password, :password_confirmation).to_h.symbolize_keys
  end

  def new_props
    {
      copy: {
        email: t("auth.fields.email"),
        heading: t("auth.password_resets.new.heading"),
        signInLink: t("auth.password_resets.new.sign_in_link"),
        signInPrompt: t("auth.password_resets.new.sign_in_prompt"),
        submit: t("auth.password_resets.new.submit")
      },
      urls: {
        signIn: sign_in_path,
        submit: password_reset_path
      },
      values: {
        email: params.dig(:password_reset, :email)&.strip&.downcase
      }
    }
  end

  def edit_props(form_error: nil)
    {
      copy: {
        heading: t("auth.password_resets.edit.heading"),
        password: t("auth.fields.password"),
        passwordConfirmation: t("auth.fields.password_confirmation"),
        signInLink: t("auth.password_resets.edit.sign_in_link"),
        signInPrompt: t("auth.password_resets.edit.sign_in_prompt"),
        submit: t("auth.password_resets.edit.submit")
      },
      formError: form_error,
      urls: {
        signIn: sign_in_path
      }
    }
  end

  def redirect_authenticated_user
    redirect_to dashboard_path if authenticated?
  end
end
