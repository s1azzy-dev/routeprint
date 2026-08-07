require "rails_helper"

RSpec.describe Airlines::ResolveUnknown, type: :interactor do
  it "resolves the protected airline by stable key" do
    airline = create(:airline, :system_placeholder)

    result = described_class.call

    expect(result).to be_success
    expect(result.value!).to eq(airline)
  end

  it "returns an explicit failure when bootstrap has not run" do
    result = described_class.call

    expect(result).to be_failure
    expect(result.failure).to eq(code: :unknown_airline_missing, errors: {})
  end
end
