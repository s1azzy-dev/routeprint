require "rails_helper"

RSpec.describe Auth::IssueSession, type: :interactor do
  subject(:result) { described_class.call(input:) }

  let(:user_identity) { create(:user_identity) }
  let(:input) do
    {
      user: user_identity.user,
      user_identity:,
      ip_address: "203.0.113.7",
      user_agent: "RSpec"
    }
  end

  around { |example| freeze_time(&example) }

  it "creates a user session with request metadata" do
    expect { result }.to change(UserSession, :count).by(1)

    expect(result).to be_success
    user_session = result.value![:user_session]

    expect(user_session).to have_attributes(
      user: user_identity.user,
      user_identity:,
      authentication_method: Auth::Constants::PASSWORD,
      user_agent: "RSpec",
      last_seen_at: Time.current,
      expires_at: 30.days.from_now
    )
    expect(user_session.ip_address.to_s).to eq("203.0.113.7")
  end

  it "stores only the token digest" do
    user_session = result.value![:user_session]
    token = result.value![:token]

    expect(user_session.token_digest).to eq(UserSession.digest_token(token))
    expect(user_session.token_digest).not_to include(token)
  end
end
