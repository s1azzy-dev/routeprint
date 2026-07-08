require "rails_helper"

RSpec.describe Auth::RegisterUser, type: :interactor do
  subject(:result) { described_class.call(input:) }

  let(:input) do
    {
      email: " New.User@Example.COM ",
      password: "not-a-real-password-123",
      password_confirmation: "not-a-real-password-123",
      locale: "ru"
    }
  end

  it "creates an active member account and password identity" do
    expect { result }.to change(User, :count).by(1)
      .and change(UserIdentity, :count).by(1)

    expect(result).to be_success
  end

  it "normalizes account and identity attributes" do
    expect(result.value![:user]).to have_attributes(
      primary_email: "new.user@example.com",
      role: "member",
      status: "active",
      locale: "ru"
    )
    expect(result.value![:user_identity]).to have_attributes(
      provider: Auth::Constants::PASSWORD,
      email: "new.user@example.com"
    )
  end

  it "stores only a password digest" do
    expect(result.value![:user_identity].password_digest).not_to include("not-a-real-password-123")
  end

  context "when the password is too short" do
    let(:input) { super().merge(password: "too-short", password_confirmation: "too-short") }

    it "returns validation errors without creating records" do
      expect { result }.not_to change { [ User.count, UserIdentity.count ] }

      expect(result).to be_failure
      expect(result.failure[:code]).to eq(:validation_error)
      expect(result.failure[:errors]).to include(:password)
    end
  end
end
