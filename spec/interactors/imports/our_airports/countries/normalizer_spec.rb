# frozen_string_literal: true

require "rails_helper"

RSpec.describe Imports::OurAirports::Countries::Normalizer do
  it "normalizes membership identity and catalog attributes" do
    result = described_class.call("id" => "302672", "code" => "xk", "name" => " Kosovo ", "continent" => "eu")

    expect(result).to be_success
    expect(result.value!).to eq(
      external_uid: "302672",
      record_kind: "country",
      normalized_payload: { "code" => "XK", "name" => "Kosovo", "continent_code" => "EU" }
    )
  end

  it "rejects a malformed membership code" do
    result = described_class.call("id" => "1", "code" => "001", "name" => "World", "continent" => "EU")

    expect(result).to be_failure
    expect(result.failure[:code]).to eq(:invalid_country_code)
  end
end
