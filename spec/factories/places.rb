FactoryBot.define do
  factory :place do
    kind { "airport" }
    sequence(:name) { |n| "Airport #{n}" }
    municipality_name { "London" }
    country_code { "GB" }
    region_code { "GB-ENG" }
    continent_code { "EU" }
    location do
      RGeo::Geographic.spherical_factory(srid: 4326).point(-0.461941, 51.4706)
    end
    time_zone { "Europe/London" }
    time_zone_source { "manual" }
    time_zone_verified_at { Time.current }
  end
end
