FactoryBot.define do
  factory :user_session do
    user
    user_identity { association(:user_identity, user: user) }
    authentication_method { user_identity.provider }
    token_digest { UserSession.digest_token(SecureRandom.urlsafe_base64(48)) }
    last_seen_at { Time.current }
    expires_at { 30.days.from_now }
    revoked_at { nil }
  end
end
