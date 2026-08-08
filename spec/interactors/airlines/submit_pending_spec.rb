require "rails_helper"

RSpec.describe Airlines::SubmitPending, type: :interactor do
  let(:user) { create(:user) }

  it "creates a global name-only pending airline with immutable submitter audit" do
    result = submit(name: "  Example   Air  ")

    expect(result).to be_success
    expect(result.value!).to include(reused: false)
    expect_name_only_candidate(result.value!.fetch(:airline))
  end

  it "infers supported designator systems" do
    iata_result = submit(name: "Two Character Air", code: "a1")
    icao_result = submit(name: "Three Letter Air", code: "abc")

    expect(iata_result.value!.fetch(:airline).designators.first).to have_attributes(system: "iata", code: "A1")
    expect(icao_result.value!.fetch(:airline).designators.first).to have_attributes(system: "icao", code: "ABC")
  end

  it "persists optional canonical country evidence" do
    country = create(:country)

    result = submit(name: "Country Air", country_id: country.id)

    expect(result).to be_success
    expect(result.value!.fetch(:airline).country).to eq(country)
    expect(result.value!.fetch(:airline).submission.submitted_country).to eq(country)
  end

  it "reuses an exact normalized pending submission" do
    country = create(:country)
    original = submit(name: "Example Air", code: "e1", country_id: country.id)

    expect do
      result = submit(
        user: create(:user),
        name: "  example   AIR ",
        code: " E1 ",
        country_id: country.id
      )

      expect(result).to be_success
      expect(result.value!).to include(airline: original.value!.fetch(:airline), reused: true)
    end.not_to change { [ Airline.count, AirlineSubmission.count, AirlineDesignator.count ] }
  end

  it "allows a confirmed distinct candidate that shares a public code" do
    existing = create(:airline, :approved)
    create(:airline_designator, airline: existing, system: "iata", code: "ZZ")

    result = submit(name: "Another Airline", code: "ZZ")

    expect(result).to be_success
    expect(result.value!.fetch(:airline)).not_to eq(existing)
    expect(result.value!.fetch(:airline).designators.first.code).to eq("ZZ")
  end

  it "rejects malformed or unconfirmed input without partial persistence" do
    results = [
      submit(name: " "),
      submit(name: "Bad Code Air", code: "ABCD"),
      submit(name: "Unconfirmed Air", confirmed: false),
      submit(name: "Missing Country Air", country_id: SecureRandom.uuid)
    ]

    expect(results).to all(be_failure)
    expect(results.map { |result| result.failure.fetch(:code) }).to all(eq(:validation_error))
    expect([ Airline.count, AirlineSubmission.count, AirlineDesignator.count ]).to eq([ 0, 0, 0 ])
  end

  def submit(user: self.user, name:, code: nil, country_id: nil, confirmed: true)
    described_class.call(input: { user:, name:, code:, country_id:, confirmed: })
  end

  def expect_name_only_candidate(airline)
    expect(airline).to have_attributes(
      name: "Example Air",
      review_status: "pending",
      operational_status: "unknown",
      country: nil
    )
    expect(airline.submission).to have_attributes(
      submitted_by_user: user,
      submitted_name: "Example Air",
      submitted_code: nil
    )
  end
end
