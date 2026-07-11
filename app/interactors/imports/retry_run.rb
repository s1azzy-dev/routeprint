module Imports
  # Creates an optional successor run for failed items without mutating history.
  #
  # @example
  #   Imports::RetryRun.call(input: { run_id: run.id })
  # @param input [Hash] predecessor run identifier
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

      retry_result = yield persist_retry(run:, failed_items:)
      yield enqueue_items(retry_result.fetch(:items))

      Success(run: retry_result.fetch(:run), items: retry_result.fetch(:items))
    end

    private

    def find_run
      run = Imports::Run.includes(:items).find_by(id: input[:run_id])
      return Success(run) if run

      fail_with(code: :run_not_found, errors: { run_id: [ "not found" ] })
    end

    def persist_retry(run:, failed_items:)
      in_transaction do
        retry_run = create_retry_run(run:, item_count: failed_items.size)
        retry_items = create_retry_items(retry_run:, failed_items:)

        Success(run: retry_run, items: retry_items)
      end
    rescue ActiveRecord::RecordNotUnique
      fail_with(code: :run_already_active, errors: { source_key: [ "already has an active run" ] })
    end

    def create_retry_run(run:, item_count:)
      run.source.runs.create!(
        retry_of_run: run,
        mode: "retry",
        status: "queued",
        params: run.params,
        total_item_count: item_count,
        initiated_by_user_id: run.initiated_by_user_id
      )
    end

    def create_retry_items(retry_run:, failed_items:)
      failed_items.map do |item|
        retry_run.items.create!(
          item_kind: item.item_kind,
          item_key: item.item_key,
          status: "queued",
          params: item.params
        )
      end
    end

    def enqueue_items(items)
      items.each { |item| Imports::RunItemJob.perform_later(item.id) }

      Success()
    end
  end
end
