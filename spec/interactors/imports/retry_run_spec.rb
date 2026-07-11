require "rails_helper"

RSpec.describe Imports::RetryRun, type: :interactor do
  include ActiveJob::TestHelper

  subject(:result) { described_class.call(input: { run_id: run.id }) }

  let!(:source) { create(:imports_source) }
  let!(:run) { create(:imports_run, source:, status: "partially_failed", mode: "full", params: { "parser_version" => "1" }, finished_at: 1.hour.ago) }
  let!(:failed_item) { create(:imports_run_item, run:, item_key: "failed", status: "failed", params: { "row_range" => [ 1, 10 ] }) }
  let!(:succeeded_item) { create(:imports_run_item, run:, item_key: "succeeded", status: "succeeded") }

  around do |example|
    previous_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs
    example.run
  ensure
    clear_enqueued_jobs
    ActiveJob::Base.queue_adapter = previous_adapter
  end

  it "creates an auditable successor containing only failed work" do
    expect(result).to be_success

    retry_run = result.value!.fetch(:run)
    expect(retry_run).to have_attributes(retry_of_run: run, mode: "retry", status: "queued", params: run.params)
    expect(retry_run.items.pluck(:item_key)).to eq([ "failed" ])
    expect(run.reload).to have_attributes(status: "partially_failed", finished_at: be_present)
    expect(Imports::RunItemJob).to have_been_enqueued.with(retry_run.items.sole.id).on_queue("imports")
  end
end
