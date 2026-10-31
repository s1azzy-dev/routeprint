FactoryBot.define do
  factory :travel_segment do
    association :user
    departure_place { association(:airport).place }
    arrival_place { association(:airport).place }
    transport_mode { "flight" }
    departure_date { Date.new(2020, 6, 1) }
    departure_resolution { "date_only" }
    arrival_resolution { "not_provided" }
    creation_request_key { SecureRandom.uuid }
    creation_digest { Digest::SHA256.hexdigest("factory") }
    after(:build) do |segment|
      segment.build_flight_detail(marketing_airline: build(:airline, :approved)) unless segment.flight_detail
    end
  end

  factory :flight_detail do
    association :travel_segment
    association :marketing_airline, factory: [ :airline, :approved ]
  end
end
