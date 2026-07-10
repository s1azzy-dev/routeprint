module Imports
  class FailRunItem < ApplicationInteractor
    option :input

    def call
      item = input.fetch(:item)
      error = input.fetch(:error)

      item.update!(
        status: "failed",
        finished_at: Time.current,
        lease_token: nil,
        lease_expires_at: nil,
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
