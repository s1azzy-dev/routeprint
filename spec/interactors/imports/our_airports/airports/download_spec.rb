require "rails_helper"

RSpec.describe Imports::OurAirports::Airports::Download, type: :interactor do
  let!(:run) { create(:imports_run, status: "running") }
  let!(:item) { create(:imports_run_item, run:, status: "running") }
  let(:source_url) { "https://ourairports.com/data/airports.csv" }
  let(:body) { "id,name\n1,Test Airport\n" }
  let(:response) { Net::HTTPOK.new("1.1", "200", "OK") }
  let(:http) { instance_double(Net::HTTP, get: response) }
  let(:capture_artifact) { class_double(Imports::CaptureArtifact, call: Dry::Monads::Success(artifact: :artifact)) }

  before do
    allow(response).to receive(:body).and_return(body)
    allow(Net::HTTP).to receive(:start).and_yield(http)
  end

  it "downloads the response and delegates artifact persistence" do
    result = described_class.call(input: { run:, item:, source_url: }, capture_artifact:)

    expect(result).to be_success
    expect(capture_artifact).to have_received(:call).with(input: hash_including(run:, run_item: item, source_url:))
  end

  it "rejects a non-HTTPS source URL before opening a connection" do
    result = described_class.call(input: { run:, item:, source_url: "http://ourairports.com/data/airports.csv" }, capture_artifact:)

    expect(result).to be_failure
    expect(result.failure.fetch(:code)).to eq(:invalid_source_url)
    expect(Net::HTTP).not_to have_received(:start)
  end
end
