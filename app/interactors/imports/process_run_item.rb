module Imports
  # Orchestrates claim, source processing, item completion/failure, and run finalization.
  #
  # @example
  #   Imports::ProcessRunItem.call(input: { run_item_id: item.id })
  # @param input [Hash] persisted run-item identifier
  class ProcessRunItem < ApplicationInteractor
    option :input
    option :claim_run_item, default: -> { Imports::ClaimRunItem }
    option :processor, default: -> { Imports::SourceProcessor }
    option :complete_run_item, default: -> { Imports::CompleteRunItem }
    option :fail_run_item, default: -> { Imports::FailRunItem }
    option :finalize_run, default: -> { Imports::FinalizeRun }

    class ValidationContract < ApplicationContract
      params do
        required(:run_item_id).filled(:integer)
      end
    end

    def call
      item = yield find_item
      claimed = yield claim_run_item.call(input: { run_item_id: item.id })
      return Success(item:, skipped: true) if claimed.fetch(:skipped)

      processor_result = process(item)
      if processor_result.success?
        yield complete_run_item.call(input: { item:, **processor_result.value! })
      else
        yield fail_run_item.call(input: { item:, error: processor_result.failure })
      end

      yield finalize_run.call(input: { run_id: item.run_id })
      Success(item:, skipped: false)
    end

    private

    def process(item)
      processor.call(input: { run: item.run, item: })
    rescue StandardError => error
      Rails.logger.error(
        "Imports::ProcessRunItem processor_error " \
        "run_item_id=#{item.id} " \
        "#{error.full_message(highlight: false, order: :top)}"
      )
      Failure(
        code: :processor_error,
        errors: {
          exception_class: [ error.class.name ],
          exception_message: [ error.message.to_s ],
          backtrace: Array(error.backtrace)
        }
      )
    end

    def find_item
      item = Imports::RunItem.includes(:run).find_by(id: input[:run_item_id])
      return Success(item) if item

      fail_with(code: :run_item_not_found, errors: { run_item_id: [ "not found" ] })
    end
  end
end
