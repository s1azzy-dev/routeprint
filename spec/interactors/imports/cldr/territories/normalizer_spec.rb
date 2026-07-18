# frozen_string_literal: true

require "rails_helper"

RSpec.describe Imports::Cldr::Territories::Normalizer do
  it "normalizes the translated display name" do
    result = described_class.call("id" => "ru:XK", "code" => "xk", "locale" => "ru", "name" => " Косово ")

    expect(result).to be_success
    expect(result.value!).to eq(
      external_uid: "ru:XK",
      record_kind: "country_name",
      normalized_payload: { "code" => "XK", "locale" => "ru", "name" => "Косово" }
    )
  end

  it "rejects a locale outside the application catalog" do
    result = described_class.call("id" => "fr:XK", "code" => "XK", "locale" => "fr", "name" => "Kosovo")

    expect(result).to be_failure
    expect(result.failure[:code]).to eq(:unsupported_locale)
  end
end
