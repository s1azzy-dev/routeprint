# frozen_string_literal: true

require "rails_helper"

RSpec.describe SolidQueue::Record do
  it "connects worker records to the prepared queue database" do
    expect(described_class.connection_db_config.name).to eq("queue")
    expect(SolidQueue::Process.table_exists?).to be(true)
  end
end
