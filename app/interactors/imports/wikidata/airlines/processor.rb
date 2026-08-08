# frozen_string_literal: true

require "stringio"

module Imports
  module Wikidata
    module Airlines
      # Runs the bounded Wikidata airline pipeline from pages through canonical apply.
      #
      # @example
      #   Imports::Wikidata::Airlines::Processor.call(input: { run:, item: })
      # @param input [Hash] import run and its catalog run item
      class Processor < ApplicationInteractor
        option :input
        option :parser, default: -> { Imports::Wikidata::Airlines::Parser }
        option :normalizer, default: -> { Imports::Wikidata::Airlines::Normalizer }
        option :persist_source_record, default: -> { Imports::PersistSourceRecord }
        option :apply_record, default: -> { Imports::Wikidata::Airlines::ApplyRecord }
        option :reconcile_missing_upstream, default: -> { Imports::ReconcileMissingUpstream }
        option :downloader, default: -> { Imports::Wikidata::Airlines::DownloadPage }

        class ValidationContract < ApplicationContract
          params do
            required(:run).filled(type?: Imports::Run)
            required(:item).filled(type?: Imports::RunItem)
          end
        end

        def call
          run = input.fetch(:run)
          item = input.fetch(:item)
          pages = yield acquire_and_parse_pages(run:, item:)
          source_records = yield persist_raw_records(run:, pages:)
          stats = yield normalize_and_apply(run:, source_records:)

          Success(stats:)
        end

        private

        def acquire_and_parse_pages(run:, item:)
          params = run.params.to_h
          page_size = Integer(params.fetch("page_size"))
          max_pages = Integer(params.fetch("max_pages"))
          after_qid = nil
          pages = []

          (1..max_pages).each do |page_number|
            artifact = yield find_or_download_page(run:, item:, params:, page_number:, after_qid:, page_size:)
            page = yield parse_page(artifact:, page_number:)
            pages << page
            return Success(pages) if page.fetch(:qid_count) < page_size

            next_qid = page.fetch(:last_qid)
            unless next_qid.present? && (after_qid.nil? || next_qid > after_qid)
              return fail_with(code: :non_advancing_page_cursor, errors: { page_number: [ page_number ], after_qid: [ after_qid ], last_qid: [ next_qid ] })
            end
            after_qid = next_qid
          end

          fail_with(code: :source_page_limit_exceeded, errors: { max_pages: [ max_pages ] })
        rescue ArgumentError, KeyError => error
          fail_with(code: :invalid_run_params, errors: { params: [ error.message ] })
        end

        def find_or_download_page(run:, item:, params:, page_number:, after_qid:, page_size:)
          artifact = item.artifacts.where(kind: "source_dump").order(:created_at).detect do |candidate|
            metadata = candidate.metadata.to_h
            metadata["page_number"].to_i == page_number &&
              metadata["query_version"].to_s == params.fetch("query_version").to_s &&
              metadata["query_sha256"].to_s == params.fetch("query_sha256").to_s &&
              metadata["after_qid"].presence == after_qid
          end
          return Success(artifact) if artifact&.file&.attached?

          result = downloader.call(
            input: {
              run:,
              item:,
              endpoint_url: params.fetch("endpoint_url"),
              page_number:,
              after_qid:,
              page_size:,
              query_sha256: params.fetch("query_sha256")
            }
          )
          return result if result.failure?

          Success(result.value!.fetch(:artifact))
        end

        def parse_page(artifact:, page_number:)
          Success(parser.call(StringIO.new(artifact.file.download)))
        rescue JSON::ParserError, Parser::FormatError => error
          fail_with(code: :parse_error, errors: { page_number: [ page_number ], message: [ error.message.to_s.truncate(500) ] })
        end

        def persist_raw_records(run:, pages:)
          persisted = []
          failure = nil

          ApplicationRecord.transaction do
            pages.flat_map { |page| page.fetch(:records) }.each do |record|
              raw_payload = record.fetch(:raw_payload)
              result = persist_source_record.call(
                input: {
                  phase: "raw",
                  source: run.source,
                  run:,
                  record: {
                    record_kind: "airline",
                    external_uid: raw_payload.fetch("qid"),
                    raw_payload:
                  }
                }
              )
              unless result.success?
                failure = result.failure
                raise ActiveRecord::Rollback
              end

              persisted << result.value!.fetch(:source_record)
            end
          end

          return Failure(failure) if failure

          Success(persisted)
        rescue KeyError => error
          fail_with(code: :validation_error, errors: { record: [ error.message ] })
        end

        def normalize_and_apply(run:, source_records:)
          failure = nil
          failed_source_record = nil
          processed_count = 0

          ApplicationRecord.transaction do
            source_records.each do |source_record|
              failed_source_record = source_record
              normalized_result = normalizer.call(source_record.raw_payload)
              unless normalized_result.success?
                failure = normalized_result.failure
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
                failure = persist_result.failure
                raise ActiveRecord::Rollback
              end

              apply_result = apply_record.call(input: { source_record: persist_result.value!.fetch(:source_record), run:, item: input.fetch(:item) })
              unless apply_result.success?
                failure = apply_result.failure
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

          if failure
            persist_failure_issue(run:, source_record: failed_source_record, failure:)
            return Failure(failure)
          end

          Success(
            "processed_count" => processed_count,
            "succeeded_count" => processed_count,
            "issue_count" => run.issues.where(run_item: input.fetch(:item)).count
          )
        rescue KeyError => error
          fail_with(code: :validation_error, errors: { record: [ error.message ] })
        end

        def persist_failure_issue(run:, source_record:, failure:)
          return unless source_record

          code = failure.fetch(:code).to_s
          stage = %w[missing_external_uid missing_name ambiguous_name invalid_designator].include?(code) ? "normalize" : "apply"
          issue = run.issues.find_or_initialize_by(
            run_item: input.fetch(:item),
            source_record:,
            stage:,
            code:
          )
          issue.assign_attributes(
            severity: "error",
            status: "open",
            message: "Wikidata airline record failed #{stage}",
            details: {}
          )
          issue.save!
        end
      end
    end
  end
end
