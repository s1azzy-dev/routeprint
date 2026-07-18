# frozen_string_literal: true

module Imports
  module OurAirports
    module Countries
      # Normalizes one OurAirports country-membership row.
      class Normalizer
        def self.call(row)
          new(row).call
        end

        def initialize(row)
          @row = row.transform_keys(&:to_s)
        end

        def call
          external_uid = value("id")
          code = value("code")&.upcase
          name = value("name")
          continent_code = value("continent")&.upcase
          return failure(:missing_external_uid, :id) unless external_uid
          return failure(:invalid_country_code, :code) unless code&.match?(/\A[A-Z]{2}\z/)
          return failure(:missing_name, :name) unless name
          return failure(:invalid_continent_code, :continent) unless continent_code&.match?(/\A[A-Z]{2}\z/)

          Dry::Monads::Success(
            external_uid:,
            record_kind: "country",
            normalized_payload: { "code" => code, "name" => name, "continent_code" => continent_code }
          )
        end

        private

        def value(key)
          @row[key].to_s.strip.presence
        end

        def failure(code, field)
          Dry::Monads::Failure(code:, errors: { field => [ "is required or invalid" ] })
        end
      end
    end
  end
end
