module Imports
  module OurAirports
    module Airports
      # Applies one normalized OurAirports record to the canonical airport catalog.
      #
      # @example
      #   Imports::OurAirports::Airports::ApplyRecord.call(input: { source_record: })
      # @param input [Hash] normalized source record to apply
      class ApplyRecord < ApplicationInteractor
        option :input

        class ValidationContract < ApplicationContract
          params do
            required(:source_record).filled(type?: Imports::SourceRecord)
          end
        end

        def call
          source_record = input.fetch(:source_record)
          normalized = source_record.normalized_payload.to_h
          in_transaction { apply_source_record(source_record:, normalized:) }
        rescue AmbiguousMatch => error
          fail_with(code: :ambiguous_code_match, errors: { codes: [ error.message ] })
        rescue ActiveRecord::RecordInvalid => error
          fail_with(code: :validation_error, errors: error.record.errors.to_hash)
        rescue KeyError => error
          fail_with(code: :validation_error, errors: { input: [ error.message ] })
        end

        private

        def apply_source_record(source_record:, normalized:)
          country = yield find_country(normalized.fetch("country_code"))
          link = source_record.airport_source_link
          airport, strategy = link ? [ link.airport, link.match_strategy ] : find_or_build_airport(normalized)

          update_canonical_records!(airport, normalized, country:)
          persist_source_link(source_record:, airport:, strategy:) unless link
          source_record.update!(status: "applied")

          Success(airport:, match_strategy: strategy)
        end

        def persist_source_link(source_record:, airport:, strategy:)
          source_record.build_airport_source_link(
            airport:,
            match_strategy: strategy,
            confidence: strategy == "created_from_source" ? 1.0 : 0.95,
            matched_at: Time.current
          ).save!
        end

        def find_or_build_airport(normalized)
          candidates = matching_airports(normalized)
          raise AmbiguousMatch, "multiple canonical airports share the incoming code" if candidates.size > 1

          if candidates.one?
            [ candidates.first, "unambiguous_match" ]
          else
            place = Place.new
            airport = place.build_airport
            [ airport, "created_from_source" ]
          end
        end

        def matching_airports(normalized)
          scopes = []
          scopes << Airport.where(iata_code: normalized["iata_code"]) if normalized["iata_code"].present?
          scopes << Airport.where(icao_code: normalized["icao_code"]) if normalized["icao_code"].present?
          scopes.flat_map(&:to_a).uniq { |airport| airport.place_id }
        end

        def find_country(code)
          country = Country.find_by(code:)
          return Success(country) if country

          fail_with(code: :country_not_found, errors: { country_code: [ code ] })
        end

        def update_canonical_records!(airport, normalized, country:)
          place = airport.place
          place.assign_attributes(
            kind: "airport",
            name: normalized.fetch("name"),
            municipality_name: normalized["municipality_name"],
            country:,
            country_code: normalized.fetch("country_code"),
            region_code: normalized["region_code"],
            continent_code: normalized["continent_code"],
            location: point(normalized.fetch("longitude"), normalized.fetch("latitude"))
          )

          if normalized["time_zone"].present?
            place.time_zone = normalized["time_zone"]
            place.time_zone_source = normalized["time_zone_source"] || "source"
            place.time_zone_verified_at = Time.current
          end

          place.save!
          airport.assign_attributes(
            operational_status: normalized.fetch("operational_status"),
            iata_code: normalized["iata_code"],
            icao_code: normalized["icao_code"]
          )
          airport.save!
        end

        def point(longitude, latitude)
          RGeo::Geographic.spherical_factory(srid: 4326).point(longitude, latitude)
        end

        class AmbiguousMatch < StandardError; end
      end
    end
  end
end
