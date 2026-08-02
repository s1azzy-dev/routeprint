FactoryBot.define do
  factory :airline do
    sequence(:name) { |n| "Airline #{n}" }
    review_status { "pending" }
    operational_status { "unknown" }
    record_kind { "catalog" }

    trait :approved do
      review_status { "approved" }
    end

    trait :inactive do
      operational_status { "inactive" }
    end

    trait :system_placeholder do
      name { "Unknown airline" }
      review_status { "approved" }
      operational_status { "unknown" }
      record_kind { "system_placeholder" }
      system_key { "unknown_airline" }
    end
  end

  factory :airline_designator do
    association :airline
    system { "iata" }
    sequence(:code) { |n| n.to_s(36).upcase.rjust(2, "0").last(2) }
    controlled_duplicate { false }
  end

  factory :airline_submission do
    association :airline
    association :submitted_by_user, factory: :user
    submitted_name { airline.name }
    submitted_code { nil }
    submitted_country_id { nil }
  end

  factory :imports_airline_source_link, class: "Imports::AirlineSourceLink" do
    association :source_record, factory: :imports_source_record
    association :airline
    match_strategy { "created_from_source" }
    matched_at { Time.current }
  end
end
