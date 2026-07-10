FactoryBot.define do
  factory :imports_source, class: "Imports::Source" do
    key { "ourairports_airports" }
    provider_key { "ourairports" }
    dataset_key { "airports" }
    target_kind { "airport" }
    fetch_mode { "remote_dump" }
    license_key { "ourairports" }
    enabled { true }
  end
end
