module Imports
  class CompleteRunItem < ApplicationInteractor
    option :input

    def call
      item = input.fetch(:item)
      item.update!(
        status: "succeeded",
        checkpoint: input.fetch(:checkpoint, item.checkpoint),
        stats: input.fetch(:stats, item.stats),
        finished_at: Time.current,
        lease_token: nil,
        lease_expires_at: nil,
        error_code: nil,
        error_message: nil
      )

      Success(item)
    rescue ActiveRecord::RecordInvalid => error
      fail_with(code: :validation_error, errors: error.record.errors.to_hash)
    end
  end
end
