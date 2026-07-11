require "stringio"

module Imports
  module OurAirports
    module Airports
      # Runs the ordered OurAirports pipeline from acquisition through canonical apply.
      #
      # @example
      #   Imports::OurAirports::Airports::Processor.call(input: { run:, item: })
      # @param input [Hash] import run and run item
      class Processor < ApplicationInteractor
        option :input
        option :parser, default: -> { Imports::OurAirports::Airports::Parser }
        option :normalizer, default: -> { Imports::OurAirports::Airports::Normalizer }
        option :eligibility, default: -> { Imports::OurAirports::Airports::Eligibility }
        option :persist_source_record, default: -> { Imports::PersistSourceRecord }
        option :apply_record, default: -> { Imports::OurAirports::Airports::ApplyRecord }
        option :reconcile_missing_upstream, default: -> { Imports::ReconcileMissingUpstream }
        option :downloader, default: -> { Imports::OurAirports::Airports::Download }

        class ValidationContract < ApplicationContract
          params do
            required(:run).filled(type?: Imports::Run)
            required(:item).filled(type?: Imports::RunItem)
          end
        end

        def call
          run = input.fetch(:run)
          item = input.fetch(:item)
          artifact = yield find_or_download_artifact(run:, item:)
          rows = yield parse_artifact(artifact)
          source_records = yield persist_raw_records(run:, rows:)
          stats = yield apply_records(run:, source_records:)

          Success(stats:)
        end

        private

        def find_or_download_artifact(run:, item:)
          artifact = item.artifacts.where(kind: "source_dump").order(:created_at).last || run.artifacts.where(kind: "source_dump").order(:created_at).last
          return Success(artifact) if artifact&.file&.attached?

          result = downloader.call(input: { run:, item:, source_url: item.params.to_h["source_url"] })
          return result if result.failure?

          Success(result.value!.fetch(:artifact))
        end

        def parse_artifact(artifact)
          rows = parser.call(StringIO.new(artifact.file.download))
          return fail_with(code: :source_file_empty, errors: { artifact_id: [ artifact.id ] }) if rows.empty?

          Success(rows)
        rescue CSV::MalformedCSVError => error
          fail_with(code: :parse_error, errors: { message: [ error.message.to_s.truncate(500) ] })
        end

        def persist_raw_records(run:, rows:)
          persisted = []
          failure = nil

          ApplicationRecord.transaction do
            rows.each do |parsed|
              row_number = parsed.fetch(:row_number)
              raw_payload = parsed.fetch(:raw_payload)
              external_uid = raw_payload["id"].to_s.strip.presence
              unless external_uid
                failure = { code: :missing_external_uid, errors: { id: [ "is required" ], row_number: [ row_number ] } }
                raise ActiveRecord::Rollback
              end

              result = persist_source_record.call(
                input: {
                  phase: "raw",
                  source: run.source,
                  run:,
                  record: {
                    record_kind: "airport",
                    external_uid:,
                    raw_payload:
                  }
                }
              )
              if result.failure?
                failure = with_row_number(result.failure, row_number)
                raise ActiveRecord::Rollback
              end

              persisted << { source_record: result.value!.fetch(:source_record), row_number: }
            end
          end

          return Failure(failure) if failure

          Success(persisted)
        end

        def apply_records(run:, source_records:)
          processed_count = 0
          failure = nil

          ApplicationRecord.transaction do
            source_records.each do |entry|
              source_record = entry.fetch(:source_record)
              row_number = entry.fetch(:row_number)
              normalized_result = normalizer.call(source_record.raw_payload)
              unless normalized_result.success?
                failure = with_row_number(normalized_result.failure, row_number)
                raise ActiveRecord::Rollback
              end

              normalized = normalized_result.value!
              persist_result = persist_source_record.call(
                input: {
                  source: run.source,
                  run:,
                  record: {
                    record_kind: normalized.fetch(:record_kind),
                    external_uid: normalized.fetch(:external_uid),
                    raw_payload: source_record.raw_payload,
                    normalized_payload: normalized.fetch(:normalized_payload)
                  }
                }
              )
              unless persist_result.success?
                failure = with_row_number(persist_result.failure, row_number)
                raise ActiveRecord::Rollback
              end

              source_record = persist_result.value!.fetch(:source_record)
              eligibility_result = eligibility.call(normalized.fetch(:normalized_payload))
              unless eligibility_result.success?
                failure = with_row_number(eligibility_result.failure, row_number)
                raise ActiveRecord::Rollback
              end

              apply_result = apply_record.call(input: { source_record: })
              unless apply_result.success?
                failure = with_row_number(apply_result.failure, row_number)
                raise ActiveRecord::Rollback
              end

              processed_count += 1
            end

            reconciliation = reconcile_missing_upstream.call(input: { run: }) if run.mode_full?
            if reconciliation&.failure?
              failure = reconciliation.failure
              raise ActiveRecord::Rollback
            end
          end

          return Failure(failure) if failure

          Success(
            "processed_count" => processed_count,
            "succeeded_count" => processed_count,
            "issue_count" => 0
          )
        end

        def with_row_number(failure, row_number)
          failure.merge(errors: failure.fetch(:errors, {}).merge(row_number: [ row_number ]))
        end
      end
    end
  end
end
