module Imports
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

      processor_result = processor.call(input: { run: item.run, item: })
      if processor_result.success?
        yield complete_run_item.call(input: { item:, **processor_result.value! })
      else
        yield fail_run_item.call(input: { item:, error: processor_result.failure })
      end

      yield finalize_run.call(input: { run_id: item.run_id })
      Success(item:, skipped: false)
    end

    private

    def find_item
      item = Imports::RunItem.includes(:run).find_by(id: input[:run_item_id])
      return Success(item) if item

      fail_with(code: :run_item_not_found, errors: { run_item_id: [ "not found" ] })
    end
  end
end
