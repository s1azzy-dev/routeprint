module Imports
  class RetryRun < ApplicationInteractor
    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:run_id).filled(:integer)
      end
    end

    def call
      run = yield find_run
      failed_items = run.items.where(status: "failed").to_a
      return fail_with(code: :run_not_retryable, errors: { run_id: [ "has no failed items" ] }) if failed_items.empty?

      retry_run, retry_items = yield persist_retry(run:, failed_items:)
      yield enqueue_items(retry_items)

      Success(run: retry_run, items: retry_items)
    end

    private

    def find_run
      run = Imports::Run.includes(:items).find_by(id: input[:run_id])
      return Success(run) if run

      fail_with(code: :run_not_found, errors: { run_id: [ "not found" ] })
    end

    def persist_retry(run:, failed_items:)
      retry_run = nil
      retry_items = []

      in_transaction do
        retry_run = run.source.runs.create!(
          retry_of_run: run,
          mode: "retry",
          status: "queued",
          params: run.params,
          total_item_count: failed_items.size,
          initiated_by_user_id: run.initiated_by_user_id
        )
        retry_items = failed_items.map do |item|
          retry_run.items.create!(
            item_kind: item.item_kind,
            item_key: item.item_key,
            status: "queued",
            params: item.params,
            checkpoint: item.checkpoint
          )
        end
      end

      Success([ retry_run, retry_items ])
    rescue ActiveRecord::RecordNotUnique
      fail_with(code: :run_already_active, errors: { source_key: [ "already has an active run" ] })
    end

    def enqueue_items(items)
      items.each { |item| Imports::RunItemJob.perform_later(item.id) }

      Success()
    end
  end
end
