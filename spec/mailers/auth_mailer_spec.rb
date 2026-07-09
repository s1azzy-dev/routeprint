require "rails_helper"

RSpec.describe AuthMailer, type: :mailer do
  subject(:mail) { described_class.password_reset(user_identity:, token:) }

  let(:user_identity) { create(:user_identity, email: "identity@example.com") }
  let(:token) { UserIdentity.generate_token }

  it "sends password reset instructions to the account primary email" do
    expect(mail.to).to eq([ user_identity.user.primary_email ])
    expect(mail.subject).to eq(I18n.t("auth.password_resets.mailer.subject"))
    expect(mail.body.encoded).to include(edit_password_reset_token_url(token))
  end
end
