module Imports
  class ClaimRunItem < ApplicationInteractor
    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:run_item_id).filled(:integer)
        optional(:lease_seconds).maybe(:integer)
      end
    end

    def call
      item = yield find_item
      result = nil

      item.with_lock do
        now = Time.current

        if terminal_item?(item)
          result = Success(item:, skipped: true, reason: :terminal)
        elsif item.run.cancel_requested_at.present? || item.run.status_cancelled?
          item.update!(status: "cancelled", finished_at: now, lease_token: nil, lease_expires_at: nil)
          result = Success(item:, skipped: true, reason: :cancelled)
        elsif item.status_running? && item.lease_expires_at.present? && item.lease_expires_at > now
          result = Success(item:, skipped: true, reason: :lease_active)
        else
          claim_item(item, now)
          result = Success(item:, skipped: false)
        end
      end

      result
    end

    private

    def find_item
      item = Imports::RunItem.includes(:run).find_by(id: input[:run_item_id])
      return Success(item) if item

      fail_with(code: :run_item_not_found, errors: { run_item_id: [ "not found" ] })
    end

    def terminal_item?(item)
      item.status.in?(%w[succeeded failed cancelled])
    end

    def claim_item(item, now)
      item.update!(
        status: "running",
        started_at: item.started_at || now,
        finished_at: nil,
        lease_token: SecureRandom.uuid,
        lease_expires_at: now + input.fetch(:lease_seconds, 300).to_i.seconds,
        attempts_count: item.attempts_count + 1,
        error_code: nil,
        error_message: nil
      )
      item.run.update!(status: "running", started_at: item.run.started_at || now) if item.run.status_queued?
    end
  end
end
