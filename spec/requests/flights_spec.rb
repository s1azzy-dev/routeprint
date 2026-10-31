require "rails_helper"

RSpec.describe "Private manual flights", type: :request do
  let(:user) { create(:user) }
  let(:attributes) do
    { departure_place_id: create(:airport).place_id, arrival_place_id: create(:airport).place_id,
      departure_date: "2020-06-01", creation_request_key: SecureRandom.uuid }
  end

  it "redirects guests for pages and writes" do
    get "/flights"
    expect(response).to redirect_to(sign_in_path)
    expect { post "/flights", params: { flight: attributes } }.not_to change(TravelSegment, :count)
  end

  it "creates, shows, edits and deliberately deletes a private date-only flight" do
    authenticate_member(user)
    post "/flights", params: { flight: attributes.merge(user_id: create(:user).id) }
    flight = user.travel_segments.sole
    expect(response).to redirect_to("/flights/#{flight.id}")
    get response.location
    expect(inertia.props.dig(:flight, :departureDate)).to eq("2020-06-01")
    patch "/flights/#{flight.id}", params: { flight: attributes.merge(flight_number: "ab1") }
    expect(flight.reload.flight_detail.flight_number).to eq("AB1")
    delete "/flights/#{flight.id}", params: { confirmed: true }
    expect(TravelSegment.exists?(flight.id)).to be(false)
  end

  it "returns indistinguishable not-found responses for foreign records" do
    flight = create(:travel_segment)
    authenticate_member(create(:user, role: "admin"))
    get "/flights/#{flight.id}"
    expect(response).to have_http_status(:not_found)
    patch "/flights/#{flight.id}", params: { flight: attributes }
    expect(response).to have_http_status(:not_found)
    delete "/flights/#{flight.id}", params: { confirmed: true }
    expect(response).to have_http_status(:not_found)
  end

  it "renders bounded history with private display props and stable ordering" do
    shared = { user:, departure_place: create(:airport).place, arrival_place: create(:airport).place }
    create_list(:travel_segment, 26, **shared)
    create(:travel_segment)
    authenticate_member(user)
    get "/flights"
    expect(inertia.component).to eq("Flights/Index")
    expect(inertia.props[:flights].size).to eq(25)
    expect(inertia.props[:pagination][:nextUrl]).to be_present
  end

  it "keeps display queries bounded as a page grows" do
    authenticate_member(user)
    create_display_flights(2)
    small_page_queries = history_query_count
    create_display_flights(4)
    expect(history_query_count).to be <= small_page_queries
  end

  it "preserves invalid form fields and creation identity" do
    authenticate_member(user)
    post "/flights", params: { flight: attributes.merge(arrival_time: "12:30") }
    expect(response).to have_http_status(:unprocessable_content)
    expect(inertia.props.dig(:values, :creation_request_key)).to eq(attributes[:creation_request_key])
    expect(inertia.props.dig(:formErrors, :arrival_date)).to be_present
    expect(inertia.props.dig(:values, :arrival_time)).to eq("12:30")
  end

  it "associates missing nested contract inputs with visible field errors" do
    authenticate_member(user)
    post "/flights", params: { flight: attributes.merge(departure_date: "") }
    expect(response).to have_http_status(:unprocessable_content)
    expect(inertia.props.dig(:formErrors, :departure_date)).to be_present
  end

  it "retains selected references when submitted UUIDs use uppercase letters" do
    authenticate_member(user)
    post "/flights", params: { flight: attributes.merge(departure_place_id: attributes[:departure_place_id].upcase,
      arrival_time: "12:30") }
    expect(response).to have_http_status(:unprocessable_content)
    expect(inertia.props.dig(:selected, :departure, :id)).to eq(attributes[:departure_place_id])
  end

  it "renders a fresh form and owned edit values in the user's locale" do
    user.update!(locale: "ru")
    flight = create(:travel_segment, user:)
    authenticate_member(user)
    get "/flights/new"
    expect(inertia.props.dig(:copy, :new_title)).to eq("Добавить перелёт")
    expect(inertia.props.dig(:values, :creation_request_key)).to be_present
    get "/flights/#{flight.id}/edit"
    expect(inertia.props.dig(:values, :departure_date)).to eq("2020-06-01")
    expect(inertia.props[:editing]).to be(true)
  end

  it "shows private duplicate confirmation then saves an intentional repeat" do
    authenticate_member(user)
    post "/flights", params: { flight: attributes }
    repeat = attributes.merge(creation_request_key: SecureRandom.uuid)
    post "/flights", params: { flight: repeat }
    expect(inertia.props[:duplicates].size).to eq(1)
    expect { post "/flights", params: { flight: repeat.merge(confirmed_duplicate: true) } }
      .to change(user.travel_segments, :count).by(1)
  end

  it "retains a flight when deletion has not been explicitly confirmed" do
    flight = create(:travel_segment, user:)
    authenticate_member(user)
    delete "/flights/#{flight.id}"
    expect(response).to redirect_to("/flights/#{flight.id}")
    expect(flight.reload).to be_present
  end

  it "does not treat an arbitrary nonblank delete parameter as confirmation" do
    flight = create(:travel_segment, user:)
    authenticate_member(user)
    delete "/flights/#{flight.id}", params: { confirmed: "not-confirmed" }
    expect(TravelSegment.exists?(flight.id)).to be(true)
  end

  def history_query_count
    count = 0
    subscriber = lambda do |_name, _start, _finish, _id, payload|
      count += 1 if payload[:sql].start_with?("SELECT") && !payload[:cached] && payload[:name] != "SCHEMA"
    end
    ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") { get "/flights" }
    count
  end

  def create_display_flights(count)
    create_list(:travel_segment, count, user:).each do |flight|
      carrier = create(:airline, :approved, country: create(:country))
      flight.flight_detail.update!(marketing_airline: carrier)
    end
  end
end
