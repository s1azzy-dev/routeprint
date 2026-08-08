require "rails_helper"

RSpec.describe Imports::Wikidata::Airlines::StartRun, type: :interactor do
  subject(:result) { described_class.call(input: { initiated_by_user_id: }, start_run:) }

  let(:start_run) { class_double(Imports::StartRun, call: Dry::Monads::Success(run: :run, items: :items)) }
  let(:initiated_by_user_id) { SecureRandom.uuid }
  let(:settings) { ApplicationConfig.config.imports.wikidata_airlines }

  it "builds one full server-configured paginated run" do
    expect(result).to be_success
    expect(start_run).to have_received(:call).with(input: hash_including(
      source_key: "wikidata_airlines",
      mode: "full",
      params: hash_including(expected_params),
      items: [ hash_including(item_kind: "catalog", item_key: "all") ],
      initiated_by_user_id:
    ))
  end

  def expected_params
    {
      "endpoint_url" => settings.endpoint_url,
      "query_version" => "1",
      "parser_version" => "1",
      "page_size" => settings.page_size,
      "max_pages" => settings.max_pages,
      "query_sha256" => a_string_matching(/\A[0-9a-f]{64}\z/)
    }
  end
end
