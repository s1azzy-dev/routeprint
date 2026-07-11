module Imports
  # Claims a queued run item and starts its parent run when necessary.
  #
  # @example
  #   Imports::ClaimRunItem.call(input: { run_item_id: item.id })
  # @param input [Hash] persisted run-item identifier
  class ClaimRunItem < ApplicationInteractor
    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:run_item_id).filled(:integer)
      end
    end

    def call
      item = yield find_item
      return Success(item:, skipped: true, reason: :not_queued) unless item.status_queued?

      yield claim_item(item)
      Success(item:, skipped: false)
    end

    private

    def find_item
      item = Imports::RunItem.includes(:run).find_by(id: input[:run_item_id])
      return Success(item) if item

      fail_with(code: :run_item_not_found, errors: { run_item_id: [ "not found" ] })
    end

    def claim_item(item)
      now = Time.current
      in_transaction do
        item.update!(
          status: "running",
          started_at: item.started_at || now,
          finished_at: nil,
          attempts_count: item.attempts_count + 1,
          error_code: nil,
          error_message: nil
        )
        item.run.update!(status: "running", started_at: item.run.started_at || now) if item.run.status_queued?
      end

      Success(item)
    rescue ActiveRecord::RecordInvalid => error
      fail_with(code: :validation_error, errors: error.record.errors.to_hash)
    end
  end
end
