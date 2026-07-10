require "rails_helper"

RSpec.describe Imports::RunItem, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:run).class_name("Imports::Run") }
    it { is_expected.to have_many(:artifacts).class_name("Imports::Artifact").dependent(:nullify) }
    it { is_expected.to have_many(:issues).class_name("Imports::Issue").dependent(:nullify) }
  end

  describe "validations" do
    subject(:item) { described_class.new(run: Imports::Run.new, item_kind: "file", item_key: "all", status: "queued") }

    it { is_expected.to validate_presence_of(:item_kind) }
    it { is_expected.to validate_presence_of(:item_key) }
    it { is_expected.to validate_numericality_of(:attempts_count).is_greater_than_or_equal_to(0) }
  end

  it "defines the supported statuses" do
    expect(described_class::STATUSES).to include("queued", "running", "succeeded", "failed", "cancelled")
  end
end
