FactoryBot.define do
  factory :imports_issue, class: "Imports::Issue" do
    association :run, factory: :imports_run
    stage { "parse" }
    code { "invalid_row" }
    severity { "error" }
    status { "open" }
    message { "Invalid source row" }
  end
end
