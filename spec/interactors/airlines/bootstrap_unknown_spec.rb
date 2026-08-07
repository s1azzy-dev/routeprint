require "rails_helper"

RSpec.describe Airlines::BootstrapUnknown, type: :interactor do
  it "creates the protected system airline idempotently" do
    expected_attributes = {
      name: "Unknown airline",
      review_status: "approved",
      operational_status: "unknown",
      record_kind: "system_placeholder"
    }
    first_result = described_class.call
    second_result = described_class.call

    expect(first_result).to be_success
    expect(second_result).to be_success
    expect(second_result.value!).to eq(first_result.value!)
    expect(Airline.where(system_key: "unknown_airline")).to contain_exactly(have_attributes(expected_attributes))
  end
end
