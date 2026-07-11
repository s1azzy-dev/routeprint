module Imports
  # Marks a run item as successful and persists its processing statistics.
  #
  # @example
  #   Imports::CompleteRunItem.call(input: { item:, stats: { "processed_count" => 1 } })
  # @param input [Hash] run item and optional statistics
  class CompleteRunItem < ApplicationInteractor
    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:item).filled(type?: Imports::RunItem)
        optional(:stats).maybe(:hash)
      end
    end

    def call
      item = input.fetch(:item)
      item.update!(
        status: "succeeded",
        stats: input.fetch(:stats, item.stats),
        finished_at: Time.current,
        error_code: nil,
        error_message: nil
      )

      Success(item)
    rescue ActiveRecord::RecordInvalid => error
      fail_with(code: :validation_error, errors: error.record.errors.to_hash)
    end
  end
end
