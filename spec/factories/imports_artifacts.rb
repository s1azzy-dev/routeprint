FactoryBot.define do
  factory :imports_artifact, class: "Imports::Artifact" do
    association :run, factory: :imports_run
    kind { "source_dump" }
    sha256 { SecureRandom.hex(32) }
    captured_at { Time.current }
  end
end
