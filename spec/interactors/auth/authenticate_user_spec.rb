require "rails_helper"

RSpec.describe Auth::AuthenticateUser, type: :interactor do
  subject(:result) { described_class.call(input:) }

  let(:input) { { email:, password: } }
  let(:email) { " USER@example.com " }
  let(:password) { "not-a-real-password-123" }
  let(:user) { create(:user, status:) }
  let(:status) { "active" }

  before do
    create(:user_identity, user:, email: "user@example.com", password:, password_confirmation: password)
  end

  it "authenticates active password users by normalized email" do
    expect(result).to be_success
    expect(result.value![:user]).to eq(user)
    expect(result.value![:user_identity]).to eq(user.user_identities.password.sole)
  end

  context "when the password is wrong" do
    let(:password) { "not-a-real-password-123" }
    let(:input) { { email:, password: "wrong-password-123" } }

    it "returns a generic credentials failure" do
      expect(result).to be_failure
      expect(result.failure[:code]).to eq(:invalid_credentials)
    end
  end

  context "when the user is suspended" do
    let(:status) { "suspended" }

    it "returns the same generic credentials failure" do
      expect(result).to be_failure
      expect(result.failure[:code]).to eq(:invalid_credentials)
    end
  end
end
