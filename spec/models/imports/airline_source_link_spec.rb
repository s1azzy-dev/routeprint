require "rails_helper"

RSpec.describe Imports::AirlineSourceLink, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:source_record).class_name("Imports::SourceRecord") }
    it { is_expected.to belong_to(:airline) }
  end

  describe "validations" do
    subject(:link) { build(:imports_airline_source_link) }

    it { is_expected.to validate_inclusion_of(:match_strategy).in_array(%w[external_link created_from_source manual]) }
    it { is_expected.to validate_presence_of(:matched_at) }
  end
end
