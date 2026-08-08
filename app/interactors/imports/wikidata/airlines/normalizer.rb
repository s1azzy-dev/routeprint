# frozen_string_literal: true

module Imports
  module Wikidata
    module Airlines
      # Normalizes grouped Wikidata evidence into the airline source contract.
      class Normalizer
        include Dry::Monads[:result]

        QID = /\AQ\d+\z/
        IATA_CODE = /\A[A-Z0-9]{2}\z/
        ICAO_CODE = /\A[A-Z]{3}\z/
        DAY_PRECISION = 11

        # Normalizes one grouped QID payload.
        #
        # @param raw_payload [Hash] grouped bindings from Parser
        # @return [Dry::Monads::Result] normalized source record or failure
        def self.call(raw_payload)
          new(raw_payload).call
        end

        def initialize(raw_payload)
          @raw_payload = raw_payload.to_h.deep_stringify_keys
        end

        def call
          qid = string(raw_payload["qid"])
          return failure(:missing_external_uid, qid: "must be a Wikidata QID") unless qid&.match?(QID)

          names = Array(raw_payload["name_candidates"]).filter_map { |value| string(value) }.uniq
          return failure(:missing_name, name: "is required") if names.empty?
          return failure(:ambiguous_name, name: "has multiple English labels") if names.many?

          designators = normalize_designators
          return designators if designators.failure?

          Success(
            external_uid: qid,
            record_kind: "airline",
            normalized_payload: {
              "name" => names.first,
              "country_code" => country_code,
              "country_evidence" => country_evidence,
              "operational_status" => operational_status,
              "inception_date" => exact_date_for("inception"),
              "dissolved_date" => exact_date_for("dissolved"),
              "designators" => designators.value!
            }
          )
        end

        private

        attr_reader :raw_payload

        def bindings
          Array(raw_payload["bindings"])
        end

        def evidence(kind)
          bindings.select { |binding| binding.dig("rowKind", "value") == kind }
        end

        def country_evidence
          evidence("country").map do |binding|
            {
              "qid" => entity_qid(binding.dig("item", "value")),
              "code" => string(binding.dig("value", "value"))&.upcase
            }
          end.uniq.sort_by { |entry| [ entry["qid"].to_s, entry["code"].to_s ] }
        end

        def country_code
          codes = country_evidence.filter_map { |entry| entry["code"] if entry["code"]&.match?(/\A[A-Z]{2}\z/) }.uniq
          codes.one? ? codes.first : nil
        end

        def operational_status
          ended = evidence("dissolved").any? do |binding|
            date = parse_date(binding.dig("value", "value"))
            date && date <= Date.current
          end
          ended ? "inactive" : "unknown"
        end

        def exact_date_for(kind)
          dates = preferred(evidence(kind)).filter_map do |binding|
            next unless binding.dig("precision", "value").to_i == DAY_PRECISION

            parse_date(binding.dig("value", "value"))
          end.uniq.sort

          dates.one? ? dates.first.iso8601 : nil
        end

        def normalize_designators
          grouped = %w[iata icao].flat_map do |system|
            preferred(evidence("#{system}_designator")).map { |binding| [ system, binding ] }
          end.group_by { |system, binding| [ system, string(binding.dig("value", "value"))&.upcase ] }

          normalized = []
          grouped.each do |(system, code), entries|
            pattern = system == "iata" ? IATA_CODE : ICAO_CODE
            return failure(:invalid_designator, designator: "#{system}:#{code}") unless code&.match?(pattern)

            ranges = entries.map { |_entry_system, binding| validity_range(binding) }.uniq
            return failure(:invalid_designator, designator: "#{system}:#{code} has conflicting validity") if ranges.many?

            range = ranges.first || [ nil, nil ]
            normalized << {
              "system" => system,
              "code" => code,
              "valid_from" => range.first,
              "valid_until" => range.last,
              "controlled_duplicate" => false
            }
          end

          Success(normalized.sort_by { |entry| [ entry.fetch("system"), entry.fetch("code") ] })
        end

        def validity_range(binding)
          [
            exact_qualifier_date(binding, "start", "startPrecision"),
            exact_qualifier_date(binding, "end", "endPrecision")
          ]
        end

        def exact_qualifier_date(binding, value_key, precision_key)
          return unless binding.dig(precision_key, "value").to_i == DAY_PRECISION

          parse_date(binding.dig(value_key, "value"))&.iso8601
        end

        def preferred(candidate_bindings)
          preferred_bindings = candidate_bindings.select { |binding| binding.dig("rank", "value").to_s.end_with?("PreferredRank") }
          preferred_bindings.presence || candidate_bindings
        end

        def entity_qid(uri)
          Parser::QID_URI.match(uri.to_s)&.[](1)
        end

        def parse_date(value)
          Date.iso8601(value.to_s.first(10))
        rescue Date::Error
          nil
        end

        def string(value)
          value.to_s.squish.presence
        end

        def failure(code, errors)
          Failure(code:, errors: errors.transform_values { |message| [ message ] })
        end
      end
    end
  end
end
