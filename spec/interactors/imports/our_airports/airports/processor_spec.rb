require "rails_helper"

RSpec.describe Imports::OurAirports::Airports::Processor, type: :interactor do
  let!(:run) { create(:imports_run, status: "running") }
  let!(:item) { create(:imports_run_item, run:, status: "running") }
  let!(:country) { create(:country, code: "GB", name: "United Kingdom", continent_code: "EU") }
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

  it "stops on a dirty row after persisting the complete raw stage" do
    result = described_class.call(input: { run:, item: }, parser:, normalizer:)

    expect(result).to be_failure
    expect(result.failure.fetch(:code)).to eq(:unsupported_facility_type)
    expect([ Place.count, Airport.count ]).to eq([ 0, 0 ])
    expect([ Imports::SourceRecord.count, Imports::SourceRecord.where(status: "staged").count ]).to eq([ 2, 2 ])
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
end
