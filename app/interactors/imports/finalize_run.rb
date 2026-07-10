module Imports
  class FinalizeRun < ApplicationInteractor
    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:run_id).filled(:integer)
      end
    end

    def call
      run = yield find_run
      result = nil

      run.with_lock do
        items = run.items.reload
        if items.any? { |item| item.status.in?(%w[queued running]) }
          result = Success(run:, finalized: false)
        else
          result = finalize(run, items)
        end
      end

      result
    end

    private

    def find_run
      run = Imports::Run.find_by(id: input[:run_id])
      return Success(run) if run

      fail_with(code: :run_not_found, errors: { run_id: [ "not found" ] })
    end

    def finalize(run, items)
      succeeded_count = items.count(&:status_succeeded?)
      failed_count = items.count(&:status_failed?)
      cancelled_count = items.count(&:status_cancelled?)
      status = final_status(run:, succeeded_count:, failed_count:, cancelled_count:)
      stats = run.stats.to_h.merge(
        "total_item_count" => items.size,
        "completed_item_count" => succeeded_count,
        "failed_item_count" => failed_count,
        "processed_count" => items.sum { |item| item.stats.to_h.fetch("processed_count", 0).to_i }
      )

      run.update!(
        status:,
        total_item_count: items.size,
        completed_item_count: succeeded_count,
        failed_item_count: failed_count,
        issue_count: run.issues.count,
        stats:,
        finished_at: Time.current
      )

      Success(run:, finalized: true)
    end

    def final_status(run:, succeeded_count:, failed_count:, cancelled_count:)
      return "cancelled" if run.cancel_requested_at.present? || (cancelled_count.positive? && failed_count.zero?)
      return "partially_failed" if failed_count.positive? && succeeded_count.positive?
      return "failed" if failed_count.positive?

      "succeeded"
    end
  end
end
