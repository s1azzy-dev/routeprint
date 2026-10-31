require "rails_helper"

RSpec.describe Flights::Create, :concurrent do
  self.use_transactional_tests = false

  def race_records
    user = create(:user)
    origin = create(:airport).place
    destination = create(:airport).place
    airline = create(:airline, :approved)
    attributes = { departure_place_id: origin.id, arrival_place_id: destination.id,
      departure_date: "2020-06-01", creation_request_key: SecureRandom.uuid, marketing_airline_id: airline.id }
    [ user, origin, destination, airline, attributes ]
  end

  it "commits one flight for concurrent submissions of one form" do
    user, origin, destination, airline, attributes = race_records
    results = concurrent_results(user:, attributes:)
    expect(results).to all(be_success)
    expect(results.map { |result| result.value![:flight].id }.uniq.size).to eq(1)
    expect(user.travel_segments.count).to eq(1)
  ensure
    TravelSegment.where(user_id: user.id).find_each(&:destroy!) if user
    user&.reload&.destroy!
    [ origin, destination ].compact.each(&:destroy!)
    airline&.reload&.destroy!
  end

  def concurrent_results(user:, attributes:)
    ready = Queue.new
    start = Queue.new
    threads = Array.new(2) do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop
          described_class.call(input: { user: User.find(user.id), attributes: })
        end
      end
    end
    2.times { ready.pop }
    2.times { start << true }
    threads.map(&:value)
  end
end
