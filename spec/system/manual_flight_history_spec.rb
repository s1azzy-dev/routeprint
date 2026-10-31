require "rails_helper"

RSpec.describe "Manual flight runtime documents", type: :system do
  let(:user) { create(:user) }
  let(:entry) do
    { departure_place_id: create(:airport).place_id, arrival_place_id: create(:airport).place_id,
      departure_date: "2020-06-01", creation_request_key: SecureRandom.uuid }
  end

  before do
    raw = SecureRandom.urlsafe_base64(48)
    create(:user_session, user:, token_digest: UserSession.digest_token(raw))
    request = ActionDispatch::Request.new(Rails.application.env_config)
    jar = ActionDispatch::Cookies::CookieJar.build(request, {})
    jar.signed[:user_session_token] = raw
    page.driver.browser.set_cookie("user_session_token=#{jar[:user_session_token]}")
  end

  it "serves the date-only creation, edit, detail and deletion journey" do
    visit new_flight_path
    expect(document[:component]).to eq("Flights/Form")
    page.driver.submit(:post, flights_path, { flight: entry })
    expect(document[:component]).to eq("Flights/Show")
    expect(document.dig(:props, :flight, :departureTime)).to be_nil
    edit_and_delete(user.travel_segments.sole)
    expect(document[:component]).to eq("Flights/Index")
    expect(user.travel_segments.count).to eq(0)
  end

  it "renders a duplicate warning without persisting until confirmation" do
    page.driver.submit(:post, flights_path, { flight: entry })
    another = entry.merge(creation_request_key: SecureRandom.uuid)
    page.driver.submit(:post, flights_path, { flight: another })
    expect(document.dig(:props, :duplicates).size).to eq(1)
    expect(user.travel_segments.count).to eq(1)
    page.driver.submit(:post, flights_path, { flight: another.merge(confirmed_duplicate: true) })
    expect(document[:component]).to eq("Flights/Show")
    expect(user.travel_segments.count).to eq(2)
  end

  def edit_and_delete(flight)
    visit edit_flight_path(flight)
    expect(document.dig(:props, :values, :departure_date)).to eq("2020-06-01")
    page.driver.submit(:patch, flight_path(flight), { flight: entry.merge(flight_number: "AB1") })
    expect(document.dig(:props, :flight, :flightNumber)).to eq("AB1")
    page.driver.submit(:delete, flight_path(flight), { confirmed: true })
  end

  def document
    JSON.parse(page.find("script[data-page]", visible: :all).text(:all), symbolize_names: true)
  end
end
