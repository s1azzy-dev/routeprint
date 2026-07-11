module Imports
  # Marks source records absent from a completed full snapshot as missing upstream.
  #
  # @example
  #   Imports::ReconcileMissingUpstream.call(input: { run: })
  # @param input [Hash] completed import run
  class ReconcileMissingUpstream < ApplicationInteractor
    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:run).filled(type?: Imports::Run)
      end
    end

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
