# frozen_string_literal: true

module Imports
  module Wikidata
    module Airlines
      # Applies one normalized QID-backed source record to the airline catalog.
      #
      # @example
      #   Imports::Wikidata::Airlines::ApplyRecord.call(input: { source_record: })
      # @param input [Hash] normalized Wikidata source record
      class ApplyRecord < ApplicationInteractor
        option :input

        class ValidationContract < ApplicationContract
          params do
            required(:source_record).filled(type?: Imports::SourceRecord)
            optional(:run).maybe(type?: Imports::Run)
            optional(:item).maybe(type?: Imports::RunItem)
          end
        end

        def call
          source_record = input.fetch(:source_record)
          normalized = source_record.normalized_payload.to_h

          in_transaction do
            link = source_record.airline_source_link
            airline = yield resolve_airline(link:, normalized:)
            country = resolve_country(normalized["country_code"])
            yield update_airline(airline:, normalized:, country:)
            yield sync_designators(airline:, designators: normalized.fetch("designators"))
            link ||= yield persist_source_link(source_record:, airline:)
            yield persist_match_warnings(source_record:, airline:, normalized:, country:)
            source_record.update!(status: "applied")

            Success(airline:, match_strategy: link.match_strategy)
          end
        rescue ActiveRecord::RecordInvalid => error
          fail_with(code: :validation_error, errors: error.record.errors.to_hash)
        rescue KeyError => error
          fail_with(code: :validation_error, errors: { input: [ error.message ] })
        end

        private

        def resolve_airline(link:, normalized:)
          return Success(link.airline) if link

          candidates = Airline.where(
            normalized_name: normalized.fetch("name").to_s.squish.downcase,
            review_status: %w[pending approved],
            record_kind: "catalog"
          )
          return fail_with(code: :ambiguous_airline_match, errors: { name: [ "matches an unlinked catalog airline" ] }) if candidates.exists?

          Success(Airline.new(review_status: "approved", record_kind: "catalog"))
        end

        def resolve_country(code)
          Country.find_by(code:) if code.present?
        end

        def update_airline(airline:, normalized:, country:)
          airline.assign_attributes(
            name: normalized.fetch("name"),
            review_status: "approved",
            operational_status: normalized.fetch("operational_status"),
            record_kind: "catalog",
            country:
          )
          return Success(airline) if airline.save

          fail_with(code: :validation_error, errors: airline.errors.to_hash)
        end

        def sync_designators(airline:, designators:)
          desired_keys = designators.map { |entry| [ entry.fetch("system"), entry.fetch("code") ] }
          airline.designators.each do |designator|
            designator.destroy! unless desired_keys.include?([ designator.system, designator.code ])
          end

          designators.each do |entry|
            designator = airline.designators.find_or_initialize_by(system: entry.fetch("system"), code: entry.fetch("code"))
            designator.assign_attributes(
              valid_from: entry["valid_from"],
              valid_until: entry["valid_until"],
              controlled_duplicate: entry.fetch("controlled_duplicate", false)
            )
            designator.save!
          end

          Success()
        end

        def persist_source_link(source_record:, airline:)
          link = source_record.build_airline_source_link(
            airline:,
            match_strategy: "created_from_source",
            matched_at: Time.current
          )
          return Success(link) if link.save

          fail_with(code: :validation_error, errors: link.errors.to_hash)
        end

        def persist_match_warnings(source_record:, airline:, normalized:, country:)
          warnings = []
          warnings << [ "country_not_resolved", "Country evidence did not resolve to a catalog country" ] if normalized["country_evidence"].present? && country.nil?
          if colliding_designator?(airline:, designators: normalized.fetch("designators"))
            warnings << [ "designator_collision", "A designator is also assigned to another airline" ]
          end

          warnings.each { |code, message| persist_warning(source_record:, code:, message:) }
          Success()
        end

        def colliding_designator?(airline:, designators:)
          designators.any? do |entry|
            AirlineDesignator.where(system: entry.fetch("system"), code: entry.fetch("code")).where.not(airline:).exists?
          end
        end

        def persist_warning(source_record:, code:, message:)
          run = input[:run] || source_record.last_import_run
          return unless run

          issue = run.issues.find_or_initialize_by(
            run_item: input[:item],
            source_record:,
            stage: "match",
            code:
          )
          issue.assign_attributes(severity: "warning", status: "open", message:, details: {})
          issue.save!
        end
      end
    end
  end
end
