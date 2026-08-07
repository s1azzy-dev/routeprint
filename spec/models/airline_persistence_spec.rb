require "rails_helper"

RSpec.describe "Airline catalog persistence", type: :model do
  it "uses non-global designator uniqueness and indexed candidate lookup" do
    indexes = ActiveRecord::Base.connection.indexes(:airline_designators)

    expect(indexes).to include(
      have_attributes(columns: %w[airline_id system code], unique: true),
      have_attributes(name: "index_airline_designators_on_system_and_code", unique: false)
    )
  end

  it "keeps one open pending submission fingerprint without treating codes as identity" do
    index = ActiveRecord::Base.connection.indexes(:airlines).find do |candidate|
      candidate.name == "index_airlines_on_open_pending_fingerprint"
    end

    expect(index).to have_attributes(unique: true)
    expect(index.where).to include("review_status = 'pending'")
  end

  it "uses Routeprint UUID identities and timezone-aware review evidence" do
    airline_columns = ActiveRecord::Base.connection.columns(:airlines).index_by(&:name)

    expect(airline_columns.fetch("id").type).to eq(:uuid)
    expect(airline_columns.fetch("reviewed_at").sql_type).to eq("timestamp with time zone")
    expect(airline_columns.fetch("country_id").null).to be(true)
  end
end
