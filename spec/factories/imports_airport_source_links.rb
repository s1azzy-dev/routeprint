FactoryBot.define do
  factory :imports_airport_source_link, class: "Imports::AirportSourceLink" do
    association :source_record, factory: :imports_source_record
    association :airport, factory: :airport
    match_strategy { "created_from_source" }
    confidence { 1.0 }
    matched_at { Time.current }
  end
end
