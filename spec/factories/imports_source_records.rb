FactoryBot.define do
  factory :imports_source_record, class: "Imports::SourceRecord" do
    association :source, factory: :imports_source
    record_kind { "airport" }
    sequence(:external_uid) { |n| n.to_s }
    status { "staged" }
    checksum { SecureRandom.hex(32) }
    raw_payload { { "id" => external_uid } }
    normalized_payload { { "external_uid" => external_uid } }
    first_seen_at { Time.current }
    last_seen_at { Time.current }
  end
end
