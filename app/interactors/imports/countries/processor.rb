# frozen_string_literal: true

module Imports
  module Countries
    # Captures and stages the full catalog package before one canonical apply.
    #
    # @example Imports::Countries::Processor.call(input: { run:, item: })
    # @param input [Hash] composite catalog run and its sole work item
    class Processor < ApplicationInteractor
      option :input
      option :downloader, default: -> { Imports::Countries::Download }
      option :stage_records, default: -> { Imports::Countries::StageRecords }
      option :apply_catalog, default: -> { Imports::Countries::ApplyCatalog }

      ADAPTERS = {
        "ourairports_countries" => {
          parser: Imports::OurAirports::Countries::Parser,
          normalizer: Imports::OurAirports::Countries::Normalizer
        },
        "cldr_territories_en" => {
          parser: Imports::Cldr::Territories::Parser,
          normalizer: Imports::Cldr::Territories::Normalizer
        },
        "cldr_territories_ru" => {
          parser: Imports::Cldr::Territories::Parser,
          normalizer: Imports::Cldr::Territories::Normalizer
        }
      }.freeze

      class ValidationContract < ApplicationContract
        params do
          required(:run).filled(type?: Imports::Run)
          required(:item).filled(type?: Imports::RunItem)
        end
      end

      def call
        run = input.fetch(:run)
        item = input.fetch(:item)
        processed = yield stage_artifacts(run:, item:)
        applied = yield apply_catalog.call(input: { run_id: run.id })

        Success(**processed, **applied)
      end

      private

      def stage_artifacts(run:, item:)
        totals = { "processed_count" => 0, "succeeded_count" => 0, "issue_count" => 0 }

        artifacts(item).each do |descriptor|
          adapter = ADAPTERS[descriptor.fetch("key")]
          return fail_with(code: :country_catalog_artifact_unknown, errors: { artifact_key: [ descriptor.fetch("key") ] }) unless adapter

          artifact = yield find_or_download_artifact(run:, item:, descriptor:)
          staged = yield stage_records.call(input: { run:, artifact: }, parser: adapter.fetch(:parser), normalizer: adapter.fetch(:normalizer))
          totals.keys.each { |key| totals[key] += staged.fetch(key, 0) }
        end

        Success(**totals)
      end

      def artifacts(item)
        item.params.to_h.fetch("artifacts")
      rescue KeyError
        []
      end

      def find_or_download_artifact(run:, item:, descriptor:)
        artifact = item.artifacts.order(created_at: :desc).detect do |candidate|
          candidate.file.attached? && candidate.metadata.to_h["artifact_key"] == descriptor.fetch("key")
        end
        return Success(artifact) if artifact

        result = downloader.call(
          input: descriptor.merge("run" => run, "item" => item, "artifact_key" => descriptor.fetch("key")).symbolize_keys
        )
        return result if result.failure?

        Success(result.value!.fetch(:artifact))
      end
    end
  end
end
