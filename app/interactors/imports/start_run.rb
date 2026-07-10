module Imports
  class StartRun < ApplicationInteractor
    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:source_key).filled(:string)
        required(:mode).filled(:string)
        required(:params).filled(:hash)
        required(:items).filled(:array)
        optional(:initiated_by_user_id).maybe(:string)
      end
    end

    def call
      source = yield find_source
      yield validate_mode
      persisted = yield persist_run(source)
      yield enqueue_items(persisted.fetch(:items))

      Success(run: persisted.fetch(:run), items: persisted.fetch(:items))
    end

    private

    def find_source
      source = Imports::Source.find_by(key: input.fetch(:source_key).to_s.strip)
      return fail_with(code: :source_not_found, errors: { source_key: [ "not found" ] }) unless source
      return fail_with(code: :source_disabled, errors: { source_key: [ "disabled" ] }) unless source.enabled?

      Success(source)
    end

    def validate_mode
      return Success() if Imports::Run::MODES.include?(input.fetch(:mode).to_s)

      fail_with(code: :invalid_mode, errors: { mode: [ "is not supported" ] })
    end

    def persist_run(source)
      run = nil
      items = []

      in_transaction do
        run = yield create_run(source)
        items = yield create_items(run)
      end

      Success(run:, items:)
    end

    def create_run(source)
      safe_call(
        ActiveRecord::RecordNotUnique,
        on_error: ->(_) { fail_with(code: :run_already_active, errors: { source_key: [ "already has an active run" ] }) }
      ) do
        source.runs.create!(
          retry_of_run_id: input[:retry_of_run_id],
          initiated_by_user_id: input[:initiated_by_user_id],
          mode: input.fetch(:mode),
          status: "queued",
          params: input.fetch(:params),
          total_item_count: input.fetch(:items).size
        )
      end
    end

    def create_items(run)
      safe_call(
        ActiveRecord::RecordNotUnique,
        on_error: ->(_) { fail_with(code: :run_item_already_exists, errors: { item_key: [ "already exists for this run" ] }) }
      ) do
        input.fetch(:items).map do |item_input|
          item = item_input.to_h.symbolize_keys

          run.items.create!(
            item_kind: item.fetch(:item_kind),
            item_key: item.fetch(:item_key),
            status: "queued",
            params: item.fetch(:params, {})
          )
        end
      rescue KeyError => error
        fail_with(code: :validation_error, errors: { items: [ error.message ] })
      end
    end

    def enqueue_items(items)
      items.each { |item| Imports::RunItemJob.perform_later(item.id) }

      Success()
    end
  end
end
