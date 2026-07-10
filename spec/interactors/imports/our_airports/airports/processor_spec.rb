require "rails_helper"

RSpec.describe Imports::OurAirports::Airports::Processor, type: :interactor do
  let!(:run) { create(:imports_run, status: "running") }
  let!(:item) { create(:imports_run_item, run:, status: "running") }
  let!(:artifact) do
    Imports::CaptureArtifact.call(
      input: {
        run:,
        run_item: item,
        io: StringIO.new("fixture"),
        filename: "airports.csv",
        content_type: "text/csv",
        kind: "source_dump"
      }
    ).value!.fetch(:artifact)
  end
  let(:rows) do
    [
      { row_number: 2, raw_payload: { "id" => "1" } },
      { row_number: 3, raw_payload: { "id" => "2" } }
    ]
  end
  let(:normalized_payload) do
    {
      "name" => "Example Airport",
      "kind" => "airport",
      "airport_type" => "small_airport",
      "operational_status" => "active",
      "latitude" => 51.0,
      "longitude" => 0.0,
      "country_code" => "GB",
      "region_code" => "GB-ENG",
      "continent_code" => "EU",
      "iata_code" => "EXM",
      "icao_code" => "EXMP"
    }
  end
  let(:parser) { parser_for(rows) }
  let(:normalizer) { normalizer_for(normalized_payload) }

  it "continues after a dirty row and records a sanitized issue" do
    result = described_class.call(input: { run:, item: }, parser:, normalizer:)

    expect(result).to be_success
    expect_batch_outcome(result)
  end

  private

  def parser_for(parser_rows)
    Class.new { define_singleton_method(:call) { |_io| parser_rows } }
  end

  def normalizer_for(valid_payload)
    success = ->(**value) { Dry::Monads::Success(value) }
    failure = ->(**value) { Dry::Monads::Failure(value) }
    Class.new do
      define_singleton_method(:call) do |row|
        row.fetch("id") == "1" ? success.call(external_uid: "1", record_kind: "airport", normalized_payload: valid_payload) : failure.call(code: :unsupported_facility_type, errors: { type: [ "heliport" ] })
      end
    end
  end

  def expect_batch_outcome(result)
    expect(result.value!.fetch(:stats)).to include("processed_count" => 2, "succeeded_count" => 1, "issue_count" => 1)
    expect(Place.count).to eq(1)
    expect(Imports::Issue.count).to eq(1)
    expect(Imports::Issue.first).to have_attributes(code: "unsupported_facility_type", message: '{"type":["heliport"]}')
    expect(Imports::SourceRecord.find_by(external_uid: "2")).to be_status_unresolved
  end
end
