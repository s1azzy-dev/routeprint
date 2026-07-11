require "rails_helper"

RSpec.describe Imports::RecordSnapshot, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:source_record).class_name("Imports::SourceRecord") }
    it { is_expected.to belong_to(:run).class_name("Imports::Run") }
  end

  describe "validations" do
    subject(:snapshot) { described_class.new(checksum: "abc123", captured_at: Time.current) }

    it { is_expected.to validate_presence_of(:checksum) }
    it { is_expected.to validate_presence_of(:captured_at) }
  end
end
