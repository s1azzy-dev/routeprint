module Imports
  class ReconcileMissingUpstream < ApplicationInteractor
    option :input

    def call
      run = input.fetch(:run)
      return Success(run:, marked_count: 0) unless run.mode_full?

      marked_count = run.source.source_records.where("last_import_run_id IS NULL OR last_import_run_id <> ?", run.id).update_all(
        status: "missing_upstream",
        updated_at: Time.current
      )
      Success(run:, marked_count:)
    rescue KeyError => error
      fail_with(code: :validation_error, errors: { input: [ error.message ] })
    end
  end
end
