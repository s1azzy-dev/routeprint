# frozen_string_literal: true

module Imports
  module Countries
    # Applies a complete staged country-catalog package to canonical records.
    #
    # @example Imports::Countries::ApplyCatalog.call(input: { run_id: run.id })
    # @param input [Hash] composite country-catalog run identifier
    class ApplyCatalog < ApplicationInteractor
      option :input

      class ValidationContract < ApplicationContract
        params do
          required(:run_id).filled(:integer)
        end
      end

      def call
        run = yield find_run
        countries = country_records(run)
        names = country_name_records(run)
        yield validate_names(countries:, names:)
        apply(countries:, names:)
      end

      private

      def find_run
        run = Imports::Run.find_by(id: input.fetch(:run_id), source: Imports::Source.find_by(key: source_key))
        return Success(run) if run

        fail_with(code: :country_catalog_run_not_found, errors: { run_id: [ "not found" ] })
      end

      def country_records(run)
        run.source_records.where(record_kind: "country").order(:id).to_a
      end

      def country_name_records(run)
        run.source_records.where(record_kind: "country_name").order(:id).to_a
      end

      def validate_names(countries:, names:)
        return fail_with(code: :country_catalog_incomplete, errors: { country_codes: [ "no country records" ] }) if countries.empty?

        names_by_code_and_locale = names.index_by do |record|
          payload = record.normalized_payload.to_h
          [ payload.fetch("code"), payload.fetch("locale") ]
        end
        missing = countries.flat_map do |record|
          code = record.normalized_payload.fetch("code")
          I18n.available_locales.map(&:to_s).filter_map { |locale| code unless names_by_code_and_locale[[ code, locale ]] }
        end.uniq
        return Success() if missing.empty?

        fail_with(code: :country_catalog_incomplete, errors: { country_codes: missing.sort })
      end

      def apply(countries:, names:)
        names_by_code_and_locale = names.index_by do |record|
          payload = record.normalized_payload.to_h
          [ payload.fetch("code"), payload.fetch("locale") ]
        end
        applied_count = 0

        ApplicationRecord.transaction do
          countries.each do |country_record|
            payload = country_record.normalized_payload.to_h
            country = Country.find_or_initialize_by(code: payload.fetch("code"))
            country.assign_attributes(name: payload.fetch("name"), continent_code: payload.fetch("continent_code"))
            country.save!
            link_country(country_record, country)

            I18n.available_locales.map(&:to_s).each do |locale|
              name_record = names_by_code_and_locale.fetch([ country.code, locale ])
              country_name = country.country_names.find_or_initialize_by(locale:)
              country_name.name = name_record.normalized_payload.fetch("name")
              country_name.save!
              link_country_name(name_record, country_name)
              name_record.update!(status: "applied")
            end

            country_record.update!(status: "applied")
            applied_count += 1
          end
        end

        Success(applied: true, country_count: applied_count)
      rescue ActiveRecord::RecordInvalid => error
        fail_with(code: :validation_error, errors: error.record.errors.to_hash)
      end

      def link_country(source_record, country)
        link = source_record.country_source_link || source_record.build_country_source_link
        link.update!(country:, matched_at: Time.current)
      end

      def link_country_name(source_record, country_name)
        link = source_record.country_name_source_link || source_record.build_country_name_source_link
        link.update!(country_name:, matched_at: Time.current)
      end

      def source_key
        ApplicationConfig.config.imports.countries.source_key
      end
    end
  end
end
