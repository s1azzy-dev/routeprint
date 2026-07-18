# frozen_string_literal: true

require "rails_helper"

RSpec.describe Imports::OurAirports::Countries::Parser do
  it "retains source row numbers and raw membership fields" do
    rows = described_class.call(StringIO.new("id,code,name,continent\n302672,XK,Kosovo,EU\n"))

    expect(rows).to eq(
      [ { row_number: 2, raw_payload: { "id" => "302672", "code" => "XK", "name" => "Kosovo", "continent" => "EU" } } ]
    )
  end
end
