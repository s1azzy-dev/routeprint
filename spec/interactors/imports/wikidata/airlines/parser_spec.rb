require "rails_helper"

RSpec.describe Imports::Wikidata::Airlines::Parser do
  subject(:page) { described_class.call(File.open(fixture_path)) }

  let(:fixture_path) { Rails.root.join("spec/fixtures/imports/wikidata_airlines_v1.json") }

  it "groups the bounded SPARQL response by QID without losing raw bindings" do
    expect(page).to include(binding_count: 21, qid_count: 5, last_qid: "Q1156345")

    records = page.fetch(:records).index_by { |record| record.fetch(:raw_payload).fetch("qid") }
    expect(records.keys).to contain_exactly("Q100153989", "Q101208211", "Q101208285", "Q102428077", "Q1156345")
    union = records.fetch("Q101208211").fetch(:raw_payload)
    expect(union.fetch("name")).to eq("Union of Burma Airways")
    expect(union.fetch("bindings")).to include(hash_including("rowKind" => hash_including("value" => "iata_designator")))
    expect(records.fetch("Q102428077").fetch(:raw_payload).fetch("name")).to be_nil
  end

  it "rejects malformed SPARQL result JSON" do
    expect { described_class.call(StringIO.new("not-json")) }.to raise_error(JSON::ParserError)
  end
end
