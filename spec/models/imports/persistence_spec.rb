require "rails_helper"

RSpec.describe "Import foundation persistence", type: :model do
  it "keeps source identities and run item keys structurally unique" do
    source_indexes = ActiveRecord::Base.connection.indexes(:import_sources)
    record_indexes = ActiveRecord::Base.connection.indexes(:import_source_records)
    item_indexes = ActiveRecord::Base.connection.indexes(:import_run_items)

    expect(source_indexes).to include(have_attributes(name: "index_import_sources_on_key", unique: true))
    expect(record_indexes).to include(have_attributes(name: "index_import_source_records_on_identity", unique: true))
    expect(item_indexes).to include(have_attributes(name: "index_import_run_items_on_run_kind_and_key", unique: true))
  end

  it "keeps at most one active run per source" do
    index = ActiveRecord::Base.connection.indexes(:import_runs).find do |candidate|
      candidate.name == "index_import_runs_on_source_id_active"
    end

    expect(index).to have_attributes(unique: true)
    expect(index.where).to include("queued")
    expect(index.where).to include("running")
  end
end
