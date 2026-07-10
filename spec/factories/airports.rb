FactoryBot.define do
  factory :airport do
    association :place
    operational_status { "active" }
    iata_code { "LHR" }
    icao_code { "EGLL" }
  end
end
