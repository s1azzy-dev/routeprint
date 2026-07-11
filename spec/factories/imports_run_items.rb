FactoryBot.define do
  factory :imports_run_item, class: "Imports::RunItem" do
    association :run, factory: :imports_run
    item_kind { "file" }
    item_key { "all" }
    status { "queued" }
    params { {} }
    stats { {} }
  end
end
