module Imports
  class RunItemJob < ApplicationJob
    queue_as :imports
    limits_concurrency to: 1, key: ->(run_item_id) { run_item_id }, duration: 10.minutes

    def perform(run_item_id)
      result = Imports::ProcessRunItem.call(input: { run_item_id: })
      return if result.success?

      failure = result.failure
      raise StandardError, "Import run item failed: #{failure[:code]}"
    end
  end
end
