require "rails_helper"

RSpec.describe Imports::Source, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:runs).class_name("Imports::Run").dependent(:restrict_with_exception) }
    it { is_expected.to have_many(:source_records).class_name("Imports::SourceRecord").dependent(:restrict_with_exception) }
  end

  describe "validations" do
    subject(:source) do
      described_class.new(
        key: "ourairports_airports",
        provider_key: "ourairports",
        dataset_key: "airports",
        target_kind: "airport",
        fetch_mode: "remote_dump",
        license_key: "ourairports"
      )
    end

    it { is_expected.to validate_presence_of(:key) }
    it { is_expected.to validate_presence_of(:provider_key) }
    it { is_expected.to validate_presence_of(:dataset_key) }
    it { is_expected.to validate_presence_of(:target_kind) }
    it { is_expected.to validate_inclusion_of(:fetch_mode).in_array(described_class::FETCH_MODES) }
    it { is_expected.to validate_presence_of(:license_key) }
  end

  it "normalizes stable source keys" do
    source = described_class.new(key: "  ourairports_airports  ", provider_key: " OurAirports ")

    source.validate

    expect(source.key).to eq("ourairports_airports")
    expect(source.provider_key).to eq("ourairports")
  end
end
