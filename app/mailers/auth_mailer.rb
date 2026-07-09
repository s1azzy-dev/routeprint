class AuthMailer < ApplicationMailer
  def password_reset(user_identity:, token:)
    @reset_url = edit_password_reset_token_url(token)

    mail(
      to: user_identity.user.primary_email,
      subject: t("auth.password_resets.mailer.subject")
    )
  end
end
