FactoryBot.define do
  factory :imports_run, class: "Imports::Run" do
    association :source, factory: :imports_source
    mode { "full" }
    status { "queued" }
    params { {} }
    stats { {} }
  end
end
