FactoryBot.define do
  factory :country do
    sequence(:code) do |n|
      first = ((n - 1) / 26 % 26 + 65).chr
      second = ((n - 1) % 26 + 65).chr
      "#{first}#{second}"
    end
    sequence(:name) { |n| "Country #{n}" }
    continent_code { "EU" }
  end

  factory :country_name do
    association :country
    locale { "en" }
    sequence(:name) { |n| "Country name #{n}" }
  end
end
