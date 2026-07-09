require "rails_helper"

RSpec.describe Auth::RequestPasswordReset, type: :interactor do
  subject(:result) { described_class.call(input:) }

  let(:input) { { email: } }
  let(:email) { " USER@example.com " }
  let!(:user_identity) { create(:user_identity, email: "user@example.com") }

  around { |example| freeze_time(&example) }

  it "stores only a reset token digest and timestamp" do
    expect { result }.to change { user_identity.reload.password_reset_token_digest }.from(nil)
      .and change { user_identity.reload.password_reset_sent_at }.from(nil).to(Time.current)

    expect(result).to be_success
  end

  it "delivers a reset email to the account primary email" do
    expect { result }.to change(ActionMailer::Base.deliveries, :count).by(1)

    expect(ActionMailer::Base.deliveries.last.to).to eq([ user_identity.user.primary_email ])
  end

  context "when the account does not exist" do
    let(:email) { "missing@example.com" }

    it "returns success without sending email" do
      expect { result }.not_to change(ActionMailer::Base.deliveries, :count)

      expect(result).to be_success
    end
  end
end
