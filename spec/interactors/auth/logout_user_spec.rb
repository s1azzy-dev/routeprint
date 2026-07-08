require "rails_helper"

RSpec.describe Auth::LogoutUser, type: :interactor do
  subject(:result) { described_class.call(input:) }

  let(:user_session) { create(:user_session) }
  let(:input) { { user_session: } }

  it "revokes the current user session" do
    expect { result }.to change { user_session.reload.revoked_at }.from(nil)
    expect(result).to be_success
    expect(result.value![:user_session]).to eq(user_session)
  end

  context "when the session is already revoked" do
    let(:user_session) { create(:user_session, revoked_at: 1.minute.ago) }

    it "stays successful" do
      expect(result).to be_success
    end
  end
end
