require "rails_helper"

RSpec.describe Imports::AirportSourceLink, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:source_record).class_name("Imports::SourceRecord") }
    it { is_expected.to belong_to(:airport) }
  end

  describe "validations" do
    subject(:link) do
      described_class.new(
        source_record: Imports::SourceRecord.new,
        airport: Airport.new,
        match_strategy: "created_from_source",
        confidence: 1.0,
        matched_at: Time.current
      )
    end

    it { is_expected.to validate_presence_of(:match_strategy) }
    it { is_expected.to validate_numericality_of(:confidence).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(1) }
    it { is_expected.to validate_presence_of(:matched_at) }
  end
end
