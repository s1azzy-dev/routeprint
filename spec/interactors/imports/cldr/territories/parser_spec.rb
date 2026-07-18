# frozen_string_literal: true

require "rails_helper"

RSpec.describe Imports::Cldr::Territories::Parser do
  it "keeps only two-letter territory codes and records the document locale" do
    document = { "main" => { "ru" => { "localeDisplayNames" => { "territories" => { "GB" => "Великобритания", "001" => "мир", "US-alt-short" => "США" } } } } }.to_json

    rows = described_class.call(StringIO.new(document))

    expect(rows).to eq(
      [ { row_number: 1, raw_payload: { "id" => "ru:GB", "code" => "GB", "locale" => "ru", "name" => "Великобритания" } } ]
    )
  end
end
