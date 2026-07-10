module Imports
  class RecordIssue < ApplicationInteractor
    option :input

    def call
      run = input.fetch(:run)
      run_item = input[:run_item]
      source_record = input[:source_record]
      issue = nil

      in_transaction do
        issue = run.issues.create!(
          run_item:,
          source_record:,
          stage: input.fetch(:stage),
          code: input.fetch(:code),
          severity: input.fetch(:severity),
          status: "open",
          message: input.fetch(:message).to_s.truncate(500),
          details: input.fetch(:details, {}).to_h,
          row_locator: input[:row_locator]
        )
        source_record&.update!(status: "unresolved")
        run.update!(issue_count: run.issue_count + 1)

        if run_item
          stats = run_item.stats.to_h
          stats["issue_count"] = stats.fetch("issue_count", 0).to_i + 1
          run_item.update!(stats:)
        end
      end

      Success(issue:)
    rescue ActiveRecord::RecordInvalid => error
      fail_with(code: :validation_error, errors: error.record.errors.to_hash)
    rescue KeyError => error
      fail_with(code: :validation_error, errors: { input: [ error.message ] })
    end
  end
end
