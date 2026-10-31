module Flights
  # Canonical form values used for validation, replay comparison, and redisplay.
  module EntryAttributes
    FIELDS = %i[departure_place_id arrival_place_id departure_date arrival_date
      departure_time arrival_time marketing_airline_id operating_airline_id flight_number].freeze

    def self.normalize(attributes)
      values = attributes.symbolize_keys
      FIELDS.to_h do |key|
        value = values[key].to_s.strip.presence
        value = value&.upcase if key == :flight_number
        value = value&.downcase if key.to_s.end_with?("_id")
        [ key, value ]
      end
    end

    def self.digest(attributes)
      Digest::SHA256.hexdigest(normalize(attributes).to_json)
    end
  end
end
