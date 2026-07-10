module Imports
  class RecoverStaleRunItems < ApplicationInteractor
    option :input

    def call
      recovered = []
      stale_scope.find_each do |item|
        item.with_lock do
          next unless item.status_running? && item.lease_expires_at.present? && item.lease_expires_at <= Time.current

          item.update!(status: "queued", lease_token: nil, lease_expires_at: nil)
          recovered << item
        end
      end

      Success(items: recovered)
    end

    private

    def stale_scope
      scope = Imports::RunItem.where(status: "running").where("lease_expires_at <= ?", Time.current)
      return scope if input[:run_id].blank?

      scope.where(run_id: input.fetch(:run_id))
    end
  end
end
