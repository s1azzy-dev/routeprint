require "rails_helper"

RSpec.describe Current, type: :model do
  it "tracks the current user and user session" do
    user = build_stubbed(:user)
    user_identity = build_stubbed(:user_identity, user:)
    user_session = build_stubbed(:user_session, user:, user_identity:)

    described_class.user = user
    described_class.user_session = user_session

    expect(described_class.user).to eq(user)
    expect(described_class.user_session).to eq(user_session)
  ensure
    described_class.reset
  end
end
