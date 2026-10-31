require "rails_helper"

RSpec.describe TimeZones::ResolveLocalTime do
  it "preserves date-only precision without warnings or midnight" do
    expect(described_class.call(date: Date.new(2020, 1, 1), time: nil, zone: "Europe/London"))
      .to include(resolution: "date_only", local_at: nil, at: nil, offset_seconds: nil)
  end

  it "resolves a civil value independently of application timezone" do
    result = described_class.call(date: Date.new(2020, 6, 1), time: "12:30", zone: "Europe/London")
    expect(result).to include(resolution: "resolved", at: Time.utc(2020, 6, 1, 11, 30), offset_seconds: 3600)
    expect(result[:local_at].strftime("%H:%M")).to eq("12:30")
  end

  it "retains ambiguous, nonexistent and missing-zone values without guessing" do
    [ [ "2020-10-25", "01:30", "Europe/London", "ambiguous" ],
      [ "2020-03-29", "01:30", "Europe/London", "nonexistent" ],
      [ "2020-06-01", "12:30", nil, "missing_zone" ] ].each do |date, time, zone, status|
      result = described_class.call(date: Date.iso8601(date), time:, zone:)
      expect(result).to include(resolution: status, at: nil, offset_seconds: nil)
      expect(result[:local_at]).to be_present
    end
  end
end
