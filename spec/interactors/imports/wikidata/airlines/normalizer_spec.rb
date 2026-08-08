require "rails_helper"

RSpec.describe Imports::Wikidata::Airlines::Normalizer do
  let(:records) do
    Imports::Wikidata::Airlines::Parser.call(File.open(Rails.root.join("spec/fixtures/imports/wikidata_airlines_v1.json")))
      .fetch(:records)
      .index_by { |record| record.fetch(:raw_payload).fetch("qid") }
  end

  it "uses QID identity and keeps optional current-airline evidence nullable" do
    result = normalize("Q100153989")

    expect(result).to be_success
    expect(result.value!).to include(external_uid: "Q100153989", record_kind: "airline")
    expect(result.value!.fetch(:normalized_payload)).to include(
      "name" => "Tradewinds Airlines",
      "country_code" => "US",
      "operational_status" => "unknown",
      "inception_date" => nil,
      "dissolved_date" => nil,
      "designators" => []
    )
  end

  it "promotes only day-precise dates and retains closed-airline state" do
    union = normalize("Q101208211").value!.fetch(:normalized_payload)
    meridiana = normalize("Q1156345").value!.fetch(:normalized_payload)

    expect(union).to include("operational_status" => "inactive", "inception_date" => "1948-12-15", "dissolved_date" => nil)
    expect(union.fetch("designators").pluck("system", "code")).to contain_exactly([ "iata", "UB" ], [ "icao", "UBA" ])
    expect(meridiana).to include("operational_status" => "inactive", "inception_date" => "1991-05-03", "dissolved_date" => "2018-02-28")
    expect(meridiana.fetch("designators")).to include(
      hash_including("system" => "iata", "code" => "IG", "valid_from" => nil, "valid_until" => "2018-02-28")
    )
  end

  it "rejects a row without a usable English name" do
    result = normalize("Q102428077")

    expect(result).to be_failure
    expect(result.failure.fetch(:code)).to eq(:missing_name)
  end

  it "rejects malformed supplied designators" do
    raw_payload = records.fetch("Q101208211").fetch(:raw_payload).deep_dup
    binding = raw_payload.fetch("bindings").find { |entry| entry.dig("rowKind", "value") == "iata_designator" }
    binding.fetch("value")["value"] = "INVALID"

    result = described_class.call(raw_payload)

    expect(result).to be_failure
    expect(result.failure.fetch(:code)).to eq(:invalid_designator)
  end

  private

  def normalize(qid)
    described_class.call(records.fetch(qid).fetch(:raw_payload))
  end
end
