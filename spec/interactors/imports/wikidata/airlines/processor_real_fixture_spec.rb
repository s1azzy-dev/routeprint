require "rails_helper"

RSpec.describe Imports::Wikidata::Airlines::Processor, type: :interactor do
  let!(:source) do
    create(:imports_source, key: "wikidata_airlines", provider_key: "wikidata", dataset_key: "airlines", target_kind: "airline", fetch_mode: "api", license_key: "cc0")
  end
  let!(:run) { create(:imports_run, source:, status: "running", mode: "full", params: run_params) }
  let!(:item) { create(:imports_run_item, run:, status: "running", item_kind: "catalog", params: run_params) }
  let(:run_params) do
    {
      "endpoint_url" => "https://query.wikidata.org/sparql",
      "page_size" => 250,
      "max_pages" => 40,
      "query_version" => "1",
      "parser_version" => "1",
      "query_sha256" => query_sha256
    }
  end
  let(:fixture_document) { JSON.parse(Rails.root.join("spec/fixtures/imports/wikidata_airlines_v1.json").read) }
  let(:query_sha256) { Digest::SHA256.file(Rails.root.join("config/imports/wikidata_airlines_v1.sparql")).hexdigest }

  before do
    create(:country, code: "US")
    create(:country, code: "MM")
    create(:country, code: "IT")
  end

  it "processes a valid bounded page through parser, persistence, and canonical apply" do
    capture_page(run:, item:, document: valid_document)

    expect { result }.to change(Airline, :count).by(4)
      .and change(Imports::SourceRecord, :count).by(4)
      .and change(Imports::AirlineSourceLink, :count).by(4)

    expect(result).to be_success
    expect(result.value!.fetch(:stats)).to include("processed_count" => 4, "succeeded_count" => 4, "issue_count" => 1)
    expect(run.issues.sole).to have_attributes(stage: "match", code: "designator_collision", severity: "warning")
    expect(Airline.find_by!(name: "Union of Burma Airways")).to have_attributes(review_status: "approved", operational_status: "inactive")
    expect(Airline.find_by!(name: "Myanmar National Airlines").designators.pluck(:code)).to contain_exactly("UB", "UBA")
  end

  it "retains the complete raw stage and rolls back canonical writes on an invalid row" do
    capture_page(run:, item:, document: fixture_document)

    expect(result).to be_failure
    expect(result.failure.fetch(:code)).to eq(:missing_name)
    expect([
      Imports::SourceRecord.where(source:).count,
      Imports::SourceRecord.where(source:, status: "staged").count,
      Imports::AirlineSourceLink.count,
      Airline.count
    ]).to eq([ 5, 5, 0, 0 ])
    expect(run.issues.pluck(:source_record_id, :stage, :code)).to eq([
      [ Imports::SourceRecord.find_by!(external_uid: "Q102428077").id, "normalize", "missing_name" ]
    ])
  end

  it "is idempotent across duplicate delivery and a successor full run" do
    capture_page(run:, item:, document: valid_document)
    expect(result).to be_success
    counts = [ Airline.count, AirlineDesignator.count, Imports::AirlineSourceLink.count, Imports::RecordSnapshot.count ]

    expect(described_class.call(input: { run:, item: })).to be_success
    expect([ Airline.count, AirlineDesignator.count, Imports::AirlineSourceLink.count, Imports::RecordSnapshot.count ]).to eq(counts)

    item.update!(status: "succeeded")
    run.update!(status: "succeeded")
    successor = create(:imports_run, source:, status: "running", mode: "full", params: run_params)
    successor_item = create(:imports_run_item, run: successor, status: "running", item_kind: "catalog", params: run_params)
    capture_page(run: successor, item: successor_item, document: valid_document)

    expect(described_class.call(input: { run: successor, item: successor_item })).to be_success
    expect([ Airline.count, AirlineDesignator.count, Imports::AirlineSourceLink.count, Imports::RecordSnapshot.count ]).to eq(counts)
  end

  it "lets a full retry successor safely reprocess a failed raw stage" do
    capture_page(run:, item:, document: fixture_document)
    expect(result).to be_failure
    successor, successor_item = successor_run(prior_status: "failed")
    capture_page(run: successor, item: successor_item, document: valid_document)

    successor_result = described_class.call(input: { run: successor, item: successor_item })
    expect(successor_result).to be_success
    expect(successor.retry_of_run).to eq(run)
    expect(Airline.count).to eq(4)
  end

  it "records a changed snapshot and updates only the linked airline" do
    capture_page(run:, item:, document: valid_document)
    expect(result).to be_success
    original = Airline.find_by!(name: "Tradewinds Airlines")
    successor, successor_item = successor_run
    capture_page(run: successor, item: successor_item, document: changed_name_document)

    airline_count = Airline.count
    expect do
      expect(described_class.call(input: { run: successor, item: successor_item })).to be_success
    end.to change(Imports::RecordSnapshot, :count).by(1)
    expect(Airline.count).to eq(airline_count)
    expect(original.reload.name).to eq("Tradewinds Airlines Updated")
  end

  it "marks an absent linked QID missing upstream without deleting its airline" do
    absent_airline = create(:airline, :approved, name: "Absent Air")
    absent_record = create(:imports_source_record, source:, record_kind: "airline", external_uid: "Q999", status: "applied")
    create(:imports_airline_source_link, source_record: absent_record, airline: absent_airline)
    capture_page(run:, item:, document: valid_document)

    expect(result).to be_success
    expect(absent_record.reload).to be_status_missing_upstream
    expect(absent_airline.reload).to be_present
  end

  it "advances a QID cursor and stops after an empty page" do
    set_page_bounds(page_size: 1, max_pages: 3)
    capture_page(run:, item:, document: document_for("Q100153989"), page_number: 1)
    capture_page(run:, item:, document: empty_document, page_number: 2, after_qid: "Q100153989")

    expect(result).to be_success
    expect(result.value!.fetch(:stats)).to include("processed_count" => 1)
    expect(Airline.find_by!(name: "Tradewinds Airlines")).to be_present
  end

  it "rejects a non-advancing cursor before raw or canonical persistence" do
    set_page_bounds(page_size: 1, max_pages: 3)
    page = document_for("Q100153989")
    capture_page(run:, item:, document: page, page_number: 1)
    capture_page(run:, item:, document: page, page_number: 2, after_qid: "Q100153989")

    expect(result).to be_failure
    expect(result.failure.fetch(:code)).to eq(:non_advancing_page_cursor)
    expect(Imports::SourceRecord).not_to exist
    expect(Airline).not_to exist
  end

  it "fails closed when every allowed page is full" do
    set_page_bounds(page_size: 1, max_pages: 1)
    capture_page(run:, item:, document: document_for("Q100153989"), page_number: 1)

    expect(result).to be_failure
    expect(result.failure.fetch(:code)).to eq(:source_page_limit_exceeded)
    expect(Imports::SourceRecord).not_to exist
  end

  private

  def result
    @result ||= described_class.call(input: { run:, item: })
  end

  def valid_document
    @valid_document ||= fixture_document.deep_dup.tap do |document|
      document.fetch("results").fetch("bindings").reject! do |binding|
        binding.dig("airline", "value").end_with?("Q102428077")
      end
    end
  end

  def document_for(*qids)
    fixture_document.deep_dup.tap do |document|
      document.fetch("results").fetch("bindings").select! do |binding|
        qids.any? { |qid| binding.dig("airline", "value").end_with?(qid) }
      end
    end
  end

  def empty_document
    fixture_document.deep_dup.tap { |document| document.fetch("results")["bindings"] = [] }
  end

  def changed_name_document
    valid_document.deep_dup.tap do |document|
      document.fetch("results").fetch("bindings").each do |binding|
        binding.fetch("name")["value"] = "Tradewinds Airlines Updated" if binding.dig("airline", "value").end_with?("Q100153989")
      end
    end
  end

  def set_page_bounds(page_size:, max_pages:)
    params = run_params.merge("page_size" => page_size, "max_pages" => max_pages)
    run.update!(params:)
    item.update!(params:)
  end

  def successor_run(prior_status: "succeeded")
    item.update!(status: prior_status)
    run.update!(status: prior_status)
    successor = create(:imports_run, source:, retry_of_run: (run if prior_status == "failed"), status: "running", mode: "full", params: run_params)
    successor_item = create(:imports_run_item, run: successor, status: "running", item_kind: "catalog", params: run_params)
    [ successor, successor_item ]
  end

  def capture_page(run:, item:, document:, page_number: 1, after_qid: nil)
    Imports::CaptureArtifact.call(
      input: {
        run:,
        run_item: item,
        io: StringIO.new(JSON.generate(document)),
        filename: format("wikidata-airlines-page-%04d.json", page_number),
        content_type: "application/sparql-results+json",
        kind: "source_dump",
        source_url: "https://query.wikidata.org/sparql",
        metadata: {
          "provider" => "wikidata", "dataset" => "airlines", "page_number" => page_number,
          "after_qid" => after_qid, "query_version" => "1", "query_sha256" => query_sha256
        }
      }
    ).value!.fetch(:artifact)
  end
end
