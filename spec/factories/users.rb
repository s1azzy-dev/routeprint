FactoryBot.define do
  factory :user do
    sequence(:primary_email) { |n| "user#{n}@example.com" }
    role { "member" }
    status { "active" }
    locale { "en" }
  end
end
