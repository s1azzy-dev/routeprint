module Imports
  module OurAirports
    module Airports
      # Normalizes one raw OurAirports row into the airport source schema.
      class Normalizer
        FIXED_WING_TYPES = %w[large_airport medium_airport small_airport closed_airport].freeze

        # Normalizes a raw provider row.
        #
        # @param row [Hash] provider row keyed by CSV header
        # @return [Dry::Monads::Result] normalized payload or a validation failure
        def self.call(row)
          new(row).call
        end

        # Builds a normalizer for a raw provider row.
        #
        # @param row [Hash] provider row keyed by CSV header
        def initialize(row)
          @row = row.transform_keys(&:to_s)
        end

        # Validates and transforms the provider row.
        #
        # @return [Dry::Monads::Result] normalized payload or a validation failure
        def call
          external_uid = string("id")
          return Dry::Monads::Failure(code: :missing_external_uid, errors: { id: [ "is required" ] }) if external_uid.blank?

          type = string("type")
          return Dry::Monads::Failure(code: :unsupported_facility_type, errors: { type: [ type ] }) unless FIXED_WING_TYPES.include?(type)

          latitude = decimal("latitude_deg")
          longitude = decimal("longitude_deg")
          return Dry::Monads::Failure(code: :invalid_coordinates, errors: { coordinates: [ "must be valid WGS84 coordinates" ] }) unless valid_coordinates?(latitude, longitude)

          country_code = string("iso_country")&.upcase
          return Dry::Monads::Failure(code: :invalid_country_code, errors: { iso_country: [ "must be two uppercase letters" ] }) unless country_code&.match?(/\A[A-Z]{2}\z/)

          name = string("name")
          return Dry::Monads::Failure(code: :missing_name, errors: { name: [ "is required" ] }) if name.blank?

          time_zone = string("time_zone")
          if time_zone
            begin
              TZInfo::Timezone.get(time_zone)
            rescue TZInfo::InvalidTimezoneIdentifier
              return Dry::Monads::Failure(code: :invalid_timezone, errors: { time_zone: [ "must be a valid IANA timezone" ] })
            end
          end

          iata_code = code(string("iata_code"), 3)
          icao_code = code(string("icao_code") || string("gps_code"), 4)
          ident = code(string("ident"), 4)

          Dry::Monads::Success(
            external_uid:,
            record_kind: "airport",
            normalized_payload: {
              "name" => name,
              "kind" => "airport",
              "airport_type" => type,
              "operational_status" => type == "closed_airport" ? "closed" : "active",
              "latitude" => latitude,
              "longitude" => longitude,
              "country_code" => country_code,
              "region_code" => string("iso_region")&.upcase,
              "continent_code" => string("continent")&.upcase,
              "municipality_name" => string("municipality"),
              "iata_code" => iata_code,
              "icao_code" => icao_code || ident,
              "time_zone" => time_zone,
              "time_zone_source" => time_zone ? "ourairports" : nil
            }
          )
        end

        private

        def string(key)
          value = @row[key]
          value.to_s.strip.presence
        end

        def decimal(key)
          Float(string(key), exception: false)
        end

        def valid_coordinates?(latitude, longitude)
          latitude && longitude && latitude.between?(-90, 90) && longitude.between?(-180, 180)
        end

        def code(value, length)
          normalized = value&.upcase
          normalized if normalized&.match?(/\A[A-Z0-9]{#{length}}\z/)
        end
      end
    end
  end
end
