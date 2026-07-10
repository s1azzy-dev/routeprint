require "rails_helper"

RSpec.describe Imports::StartRun, type: :interactor do
  include ActiveJob::TestHelper

  subject(:result) { described_class.call(input:) }

  let!(:source) { create(:imports_source) }
  let(:input) do
    {
      source_key: source.key,
      mode: "full",
      params: { "source_url" => "https://example.test/airports.csv", "parser_version" => "1" },
      items: [ { item_kind: "file", item_key: "all", params: { "source_url" => "https://example.test/airports.csv" } } ]
    }
  end

  around do |example|
    previous_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs
    example.run
  ensure
    clear_enqueued_jobs
    ActiveJob::Base.queue_adapter = previous_adapter
  end

  it "creates a durable run and queues item work with only the item id" do
    expect { result }.to change(Imports::Run, :count).by(1)
      .and change(Imports::RunItem, :count).by(1)

    expect(result).to be_success

    run = result.value!.fetch(:run)
    item = run.items.sole
    expect_run(run)
    expect_item(item)
  end

  private

  def expect_run(run)
    expect(run).to have_attributes(
      source:,
      mode: "full",
      status: "queued",
      total_item_count: 1,
      params: include("parser_version" => "1")
    )
  end

  def expect_item(item)
    expect(item).to have_attributes(item_kind: "file", item_key: "all", status: "queued")
    expect(Imports::RunItemJob).to have_been_enqueued.with(item.id).on_queue("imports")
  end

  it "rejects a second active run for the same source" do
    described_class.call(input:)

    duplicate = described_class.call(input:)

    expect(duplicate).to be_failure
    expect(duplicate.failure[:code]).to eq(:run_already_active)
    expect(Imports::Run.count).to eq(1)
  end
end
