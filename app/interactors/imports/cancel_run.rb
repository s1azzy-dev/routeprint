module Imports
  class CancelRun < ApplicationInteractor
    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:run_id).filled(:integer)
      end
    end

    def call
      run = yield find_run

      run.with_lock do
        return Success(run:, cancelled: true) if run.status_cancelled?
        return fail_with(code: :run_already_terminal, errors: { run_id: [ "already terminal" ] }) unless run.status.in?(%w[queued running])

        now = Time.current
        run.update!(cancel_requested_at: now)
        run.items.where(status: "queued").update_all(
          status: "cancelled",
          finished_at: now,
          updated_at: now
        )
      end

      Success(run: run.reload, cancelled: true)
    end

    private

    def find_run
      run = Imports::Run.find_by(id: input[:run_id])
      return Success(run) if run

      fail_with(code: :run_not_found, errors: { run_id: [ "not found" ] })
    end
  end
end
