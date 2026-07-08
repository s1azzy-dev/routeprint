FactoryBot.define do
  factory :user_identity do
    association :user
    provider { Auth::Constants::PASSWORD }
    sequence(:email) { |n| "identity#{n}@example.com" }
    password { "not-a-real-password-123" }
    password_confirmation { "not-a-real-password-123" }

    trait :google do
      provider { Auth::Constants::GOOGLE }
      sequence(:provider_uid) { |n| "google-uid-#{n}" }
      password { nil }
      password_confirmation { nil }
    end
  end
end
