FactoryBot.define do
  factory :imports_record_snapshot, class: "Imports::RecordSnapshot" do
    association :source_record, factory: :imports_source_record
    association :run, factory: :imports_run
    checksum { source_record.checksum }
    captured_at { Time.current }
  end
end
