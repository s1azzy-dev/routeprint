require "stringio"

module Imports
  module OurAirports
    module Airports
      class Processor < ApplicationInteractor
        option :input
        option :parser, default: -> { Imports::OurAirports::Airports::Parser }
        option :normalizer, default: -> { Imports::OurAirports::Airports::Normalizer }
        option :eligibility, default: -> { Imports::OurAirports::Airports::Eligibility }
        option :persist_source_record, default: -> { Imports::PersistSourceRecord }
        option :apply_record, default: -> { Imports::OurAirports::Airports::ApplyRecord }
        option :record_issue, default: -> { Imports::RecordIssue }
        option :reconcile_missing_upstream, default: -> { Imports::ReconcileMissingUpstream }
        option :downloader, default: -> { Imports::OurAirports::Airports::Download }

        def call
          run = input.fetch(:run)
          item = input.fetch(:item)
          artifact = item.artifacts.where(kind: "source_dump").order(:created_at).last || run.artifacts.where(kind: "source_dump").order(:created_at).last
          unless artifact
            download_result = downloader.call(input: { run:, item:, source_url: item.params.to_h["source_url"] })
            return download_result if download_result.failure?

            artifact = download_result.value!.fetch(:artifact)
          end
          return fail_with(code: :source_artifact_missing, errors: { item_id: [ item.id ] }) unless artifact&.file&.attached?

          processed_count = 0
          valid_count = 0
          issue_count = 0
          seen_external_uids = []

          parser.call(StringIO.new(artifact.file.download)).each do |parsed|
            processed_count += 1
            raw_payload = parsed.fetch(:raw_payload)
            row_number = parsed.fetch(:row_number)
            normalized_result = normalizer.call(raw_payload)

            unless normalized_result.success?
              source_record = stage_invalid_source_record(run:, raw_payload:)
              issue_count += stage_issue(run:, item:, source_record:, raw_payload:, row_number:, failure: normalized_result, stage: "normalize")
              next
            end

            normalized = normalized_result.value!
            external_uid = normalized.fetch(:external_uid)
            seen_external_uids << external_uid
            record_result = persist_source_record.call(
              input: {
                source: run.source,
                run:,
                record: {
                  record_kind: normalized.fetch(:record_kind),
                  external_uid:,
                  raw_payload:,
                  normalized_payload: normalized.fetch(:normalized_payload)
                }
              }
            )
            unless record_result.success?
              issue_count += stage_issue(run:, item:, raw_payload:, row_number:, failure: record_result, stage: "normalize")
              next
            end

            source_record = record_result.value!.fetch(:source_record)
            eligibility_result = eligibility.call(normalized.fetch(:normalized_payload))
            unless eligibility_result.success?
              issue_count += stage_issue(run:, item:, source_record:, raw_payload:, row_number:, failure: eligibility_result, stage: "normalize")
              next
            end

            apply_result = apply_record.call(input: { source_record: })
            unless apply_result.success?
              issue_count += stage_issue(run:, item:, source_record:, raw_payload:, row_number:, failure: apply_result, stage: "apply")
              next
            end

            valid_count += 1
          end

          item.checkpoint = item.checkpoint.to_h.merge("last_row_number" => processed_count)
          reconcile_missing_upstream.call(input: { run: }) if run.mode_full?
          Success(
            checkpoint: item.checkpoint,
            stats: item.stats.to_h.merge(
              "processed_count" => processed_count,
              "succeeded_count" => valid_count,
              "issue_count" => issue_count
            )
          )
        rescue CSV::MalformedCSVError => error
          fail_with(code: :parse_error, errors: { message: [ error.message.to_s.truncate(500) ] })
        end

        private

        def stage_invalid_source_record(run:, raw_payload:)
          external_uid = raw_payload["id"].to_s.strip.presence
          return unless external_uid

          result = persist_source_record.call(
            input: {
              source: run.source,
              run:,
              record: {
                record_kind: "airport",
                external_uid:,
                raw_payload:,
                normalized_payload: {}
              }
            }
          )
          result.success? ? result.value!.fetch(:source_record) : nil
        end

        def stage_issue(run:, item:, source_record: nil, raw_payload:, row_number:, failure:, stage:)
          failure_hash = failure.respond_to?(:failure) ? failure.failure : failure
          code = failure_hash.fetch(:code, :invalid_row)
          errors = failure_hash.fetch(:errors, {})
          record_issue.call(
            input: {
              run:,
              run_item: item,
              source_record:,
              stage:,
              code:,
              severity: "error",
              message: errors.to_json,
              details: { "provider" => "ourairports" },
              row_locator: { "row_number" => row_number }
            }
          )
          1
        end
      end
    end
  end
end
