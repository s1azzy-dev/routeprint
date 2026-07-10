module Imports
  class RunItemJob < ApplicationJob
    queue_as :imports

    def perform(run_item_id)
      result = Imports::ProcessRunItem.call(input: { run_item_id: })
      return if result.success?

      failure = result.failure
      raise StandardError, "Import run item failed: #{failure[:code]}"
    end
  end
end
