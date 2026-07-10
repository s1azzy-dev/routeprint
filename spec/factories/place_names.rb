FactoryBot.define do
  factory :place_name do
    association :place
    locale { "en" }
    sequence(:name) { |n| "Localized Airport #{n}" }
  end
end
