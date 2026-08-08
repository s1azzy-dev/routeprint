require "rails_helper"

RSpec.describe Imports::Wikidata::Airlines::DownloadPage, type: :interactor do
  let!(:source) do
    create(:imports_source, key: "wikidata_airlines", provider_key: "wikidata", dataset_key: "airlines", target_kind: "airline", fetch_mode: "api", license_key: "cc0")
  end
  let!(:run) { create(:imports_run, source:, status: "running") }
  let!(:item) { create(:imports_run_item, run:, status: "running", item_kind: "catalog") }
  let(:endpoint_url) { "https://query.wikidata.org/sparql" }
  let(:query_sha256) { Digest::SHA256.file(Rails.root.join("config/imports/wikidata_airlines_v1.sparql")).hexdigest }
  let(:response) { Net::HTTPOK.new("1.1", "200", "OK") }
  let(:http) { instance_double(Net::HTTP) }
  let(:received_requests) { [] }
  let(:capture_artifact) { class_double(Imports::CaptureArtifact, call: Dry::Monads::Success(artifact: :artifact)) }

  before do
    allow(response).to receive(:body).and_return('{"head":{"vars":[]},"results":{"bindings":[]}}')
    allow(http).to receive(:request) do |request|
      received_requests << request
      response
    end
    allow(Net::HTTP).to receive(:start).and_yield(http)
  end

  it "posts a validated bounded cursor query and captures one private page" do
    result = described_class.call(
      input: { run:, item:, endpoint_url:, page_number: 2, after_qid: "Q123", page_size: 250, query_sha256: },
      capture_artifact:
    )

    expect(result).to be_success
    request = received_requests.sole
    query = URI.decode_www_form(request.body).to_h.fetch("query")
    expect(query).to include('FILTER(STR(?airline) > "http://www.wikidata.org/entity/Q123")', "LIMIT 250")
    expect(capture_artifact).to have_received(:call).with(input: hash_including(
      run:, run_item: item, kind: "source_dump", source_url: endpoint_url,
      metadata: hash_including("page_number" => 2, "after_qid" => "Q123", "query_version" => "1", "query_sha256" => query_sha256)
    ))
  end

  it "rejects an invalid cursor or non-Wikidata endpoint before opening a connection" do
    bad_cursor = described_class.call(input: { run:, item:, endpoint_url:, page_number: 1, after_qid: "bad", page_size: 250, query_sha256: }, capture_artifact:)
    bad_endpoint = described_class.call(input: { run:, item:, endpoint_url: "https://example.test/sparql", page_number: 1, after_qid: nil, page_size: 250, query_sha256: }, capture_artifact:)

    expect(bad_cursor.failure.fetch(:code)).to eq(:invalid_page_cursor)
    expect(bad_endpoint.failure.fetch(:code)).to eq(:invalid_source_url)
    expect(Net::HTTP).not_to have_received(:start)
  end
end
