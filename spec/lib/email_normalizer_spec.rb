require "rails_helper"

RSpec.describe EmailNormalizer do
  describe ".normalize" do
    it "strips whitespace and lowercases email addresses" do
      expect(described_class.normalize(" USER@Example.COM ")).to eq("user@example.com")
    end

    it "returns nil for blank values" do
      expect(described_class.normalize("   ")).to be_nil
    end
  end
end
