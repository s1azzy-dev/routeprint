module Imports
  # Marks a run item as failed and stores its structured failure evidence.
  #
  # @example
  #   Imports::FailRunItem.call(input: { item:, error: { code: :parse_error, errors: {} } })
  # @param input [Hash] run item and failure result or exception
  class FailRunItem < ApplicationInteractor
    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:item).filled(type?: Imports::RunItem)
        required(:error).filled
      end
    end

    def call
      item = input.fetch(:item)
      error = input.fetch(:error)

      item.update!(
        status: "failed",
        finished_at: Time.current,
        error_code: error_code_for(error),
        error_message: error_message_for(error)
      )

      Success(item)
    rescue ActiveRecord::RecordInvalid => record_error
      fail_with(code: :validation_error, errors: record_error.record.errors.to_hash)
    end

    private

    def error_code_for(error)
      error.respond_to?(:fetch) ? error.fetch(:code).to_s : error.class.name
    end

    def error_message_for(error)
      return error.fetch(:errors, {}).to_json if error.respond_to?(:fetch)

      error.message.to_s.truncate(500)
    end
  end
end
