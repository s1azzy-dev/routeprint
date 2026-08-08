require "rails_helper"

RSpec.describe Imports::Wikidata::Airlines::ApplyRecord, type: :interactor do
  subject(:result) { described_class.call(input: { source_record:, run:, item: }) }

  let!(:source) do
    create(:imports_source, key: "wikidata_airlines", provider_key: "wikidata", dataset_key: "airlines", target_kind: "airline", fetch_mode: "api", license_key: "cc0")
  end
  let!(:run) { create(:imports_run, source:, status: "running") }
  let!(:item) { create(:imports_run_item, run:, status: "running") }
  let!(:country) { create(:country, code: "US") }
  let(:normalized_payload) do
    {
      "name" => "Example Air",
      "country_code" => "US",
      "country_evidence" => [ { "qid" => "Q30", "code" => "US" } ],
      "operational_status" => "unknown",
      "inception_date" => nil,
      "dissolved_date" => nil,
      "designators" => [ { "system" => "iata", "code" => "E1", "valid_from" => nil, "valid_until" => nil } ]
    }
  end
  let(:source_record) do
    create(:imports_source_record, source:, last_import_run: run, record_kind: "airline", external_uid: "Q123", normalized_payload:)
  end

  it "publishes a new QID-backed airline and explicit source link" do
    expect { result }.to change(Airline, :count).by(1)
      .and change(AirlineDesignator, :count).by(1)
      .and change(Imports::AirlineSourceLink, :count).by(1)

    expect(result).to be_success
    airline = result.value!.fetch(:airline)
    expect(airline).to have_attributes(name: "Example Air", review_status: "approved", operational_status: "unknown", country:)
    expect(airline.designators.sole).to have_attributes(system: "iata", code: "E1")
    expect(source_record.reload).to be_status_applied
    expect(source_record.airline_source_link).to have_attributes(airline:, match_strategy: "created_from_source")
  end

  it "creates a distinct airline for a code-only collision" do
    existing = create(:airline, :approved, name: "Other Air")
    create(:airline_designator, airline: existing, system: "iata", code: "E1")

    expect { result }.to change(Airline, :count).by(1)
    expect(result).to be_success
    expect(result.value!.fetch(:airline)).not_to eq(existing)
    expect(existing.reload.name).to eq("Other Air")
    expect(run.issues.sole).to have_attributes(source_record:, code: "designator_collision", severity: "warning")
  end

  it "does not auto-merge an exact canonical-name candidate" do
    create(:airline, :approved, name: "Example Air")

    expect(result).to be_failure
    expect(result.failure.fetch(:code)).to eq(:ambiguous_airline_match)
    expect(source_record.reload).to be_status_staged
    expect(source_record.airline_source_link).to be_nil
  end

  it "keeps unmatched country evidence without inventing a country" do
    normalized_payload["country_code"] = "ZZ"

    expect(result).to be_success
    expect(result.value!.fetch(:airline).country).to be_nil
    expect(source_record.reload.normalized_payload.fetch("country_evidence")).to be_present
    expect(run.issues.sole).to have_attributes(source_record:, code: "country_not_resolved", severity: "warning")
  end

  it "updates the linked source-owned fields without duplicating identity" do
    first = result.value!.fetch(:airline)
    source_record.update!(normalized_payload: normalized_payload.merge(
      "name" => "Example Air Updated",
      "designators" => [ { "system" => "icao", "code" => "EXA", "valid_from" => nil, "valid_until" => nil } ]
    ))

    expect { described_class.call(input: { source_record: source_record.reload, run:, item: }) }
      .not_to change(Airline, :count)

    expect(first.reload.name).to eq("Example Air Updated")
    expect(first.designators.reload.pluck(:system, :code)).to eq([ [ "icao", "EXA" ] ])
  end
end
