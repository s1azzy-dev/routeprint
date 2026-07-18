# frozen_string_literal: true

require "stringio"
require "csv"
require "json"

module Imports
  module Countries
    # Parses one captured provider artifact and stages its source records.
    #
    # @example Imports::Countries::StageRecords.call(input: { run:, artifact: }, parser:, normalizer:)
    # @param input [Hash] catalog run and captured provider artifact
    class StageRecords < ApplicationInteractor
      option :input
      option :parser
      option :normalizer
      option :persist_source_record, default: -> { Imports::PersistSourceRecord }

      class ValidationContract < ApplicationContract
        params do
          required(:run).filled(type?: Imports::Run)
          required(:artifact).filled(type?: Imports::Artifact)
        end
      end

      def call
        run = input.fetch(:run)
        artifact = input.fetch(:artifact)
        rows = yield parse_artifact(artifact)
        yield stage_records(run:, rows:)

        Success("processed_count" => rows.size, "succeeded_count" => rows.size, "issue_count" => 0)
      end

      private

      def parse_artifact(artifact)
        rows = parser.call(StringIO.new(artifact.file.download))
        return fail_with(code: :source_file_empty, errors: { artifact_id: [ artifact.id ] }) if rows.empty?

        Success(rows)
      rescue CSV::MalformedCSVError, JSON::ParserError => error
        fail_with(code: :parse_error, errors: { message: [ error.message.to_s.truncate(500) ] })
      end

      def stage_records(run:, rows:)
        failure = nil

        ApplicationRecord.transaction do
          rows.each do |entry|
            raw_payload = entry.fetch(:raw_payload)
            row_number = entry.fetch(:row_number)
            normalized = normalizer.call(raw_payload)
            unless normalized.success?
              failure = with_row_number(normalized.failure, row_number)
              raise ActiveRecord::Rollback
            end

            value = normalized.value!
            result = persist_source_record.call(
              input: {
                source: run.source,
                run:,
                record: {
                  record_kind: value.fetch(:record_kind),
                  external_uid: value.fetch(:external_uid),
                  raw_payload:,
                  normalized_payload: value.fetch(:normalized_payload)
                }
              }
            )
            unless result.success?
              failure = with_row_number(result.failure, row_number)
              raise ActiveRecord::Rollback
            end
          end
        end

        return Failure(failure) if failure

        Success()
      end

      def with_row_number(failure, row_number)
        failure.merge(errors: failure.fetch(:errors, {}).merge(row_number: [ row_number ]))
      end
    end
  end
end
