# frozen_string_literal: true

require "rails_helper"

RSpec.describe Imports::Countries::StartRun, type: :interactor do
  include ActiveJob::TestHelper

  subject(:result) { described_class.call(input: { initiated_by_user_id: initiator_id }) }

  let(:initiator_id) { create(:user).id }
  let(:settings) { ApplicationConfig.config.imports.countries }

  around do |example|
    previous_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs
    example.run
  ensure
    clear_enqueued_jobs
    ActiveJob::Base.queue_adapter = previous_adapter
  end

  before do
    create(:imports_source, key: settings.source_key, provider_key: "routeprint", dataset_key: "country_catalog", target_kind: "country")
  end

  it "creates and queues one composite run with three provider artifacts" do
    expect { result }.to change(Imports::Run, :count).by(1)
      .and change(Imports::RunItem, :count).by(1)

    expect(result).to be_success
    run = Imports::Run.sole
    item = run.items.sole
    expect(run).to have_attributes(initiated_by_user_id: initiator_id, status: "queued")
    expect(run.source.key).to eq(settings.source_key)
    expect(item.params.fetch("artifacts").pluck("key")).to contain_exactly(
      "ourairports_countries", "cldr_territories_en", "cldr_territories_ru"
    )
    expect(Imports::RunItemJob).to have_been_enqueued.with(item.id)
  end

  it "does not create a run when the catalog source is active" do
    source = Imports::Source.find_by!(key: settings.source_key)
    create(:imports_run, source:, status: "running")

    expect(result).to be_failure
    expect(result.failure[:code]).to eq(:country_source_unavailable)
    expect(Imports::Run.count).to eq(1)
    expect(Imports::RunItem.count).to eq(0)
  end

  it "does not create a run when the catalog source is disabled" do
    Imports::Source.find_by!(key: settings.source_key).update!(enabled: false)

    expect(result).to be_failure
    expect(result.failure[:code]).to eq(:country_source_unavailable)
    expect(Imports::Run).not_to exist
  end
end
