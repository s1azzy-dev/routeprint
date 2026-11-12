require "rails_helper"

RSpec.describe "Home" do
  let(:user) { create(:user, role: "admin") }
  let(:places) { create_list(:airport, 2).map(&:place).sort_by(&:id) }
  let(:flight_attributes) { { user:, departure_place: places.first, arrival_place: places.last } }

  it "renders the Routeprint Inertia shell" do
    create(:travel_segment)
    get root_path

    expect(response).to have_http_status(:ok)
    expect(inertia.component).to eq("Home/Show")
    expect(inertia.props.dig(:shell, :authenticated)).to be(false)
    expect(inertia.props.dig(:shell, :urls, :signIn)).to eq(sign_in_path)
    expect(inertia.props.dig(:shell, :urls, :signOut)).to eq(sign_out_path)
    expect(inertia.props[:flightRoutes]).to eq([])
  end

  it "shows only the basemap for a member without flights" do
    create(:travel_segment)
    authenticate_member(create(:user))

    get root_path

    expect(inertia.props[:flightRoutes]).to eq([])
  end

  it "groups complete history by airport pair and excludes other users' flights even for admins" do
    create_list(:travel_segment, 25, **flight_attributes)
    create(:travel_segment, user:, departure_place: places.last, arrival_place: places.first)
    create(:travel_segment, **flight_attributes.except(:user))
    create(:travel_segment)
    authenticate_member(user)

    get root_path

    expect(inertia.props[:flightRoutes]).to eq([ route_payload(count: 26) ])
    expect(response.cache_control[:no_store]).to be(true)
  end

  it "uses the current longitude and latitude from each airport place" do
    create(:travel_segment, **flight_attributes)
    authenticate_member(user)
    factory = RGeo::Geographic.spherical_factory(srid: 4326)
    places.first.update!(location: factory.point(-73.78, 40.64))
    places.last.update!(location: factory.point(-0.45, 51.48))
    get root_path

    expect(inertia.props[:flightRoutes]).to eq([ route_payload(count: 1) ])
  end

  def route_payload(count:)
    {
      "id" => places.map(&:id).join(":"),
      "from" => [ places.first.location.x, places.first.location.y ],
      "to" => [ places.last.location.x, places.last.location.y ],
      "count" => count
    }
  end
end
