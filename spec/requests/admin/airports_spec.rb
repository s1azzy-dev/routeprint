require "rails_helper"

RSpec.describe "Admin airports", type: :request do
  let(:raw_token) { SecureRandom.urlsafe_base64(48) }
  let!(:user_session) do
    create(
      :user_session,
      user:,
      token_digest: UserSession.digest_token(raw_token)
    )
  end
  let(:user) { create(:user, role:) }
  let(:role) { "admin" }
  let!(:airport) { create(:airport) }

  before { set_session_cookie(raw_token) }

  describe "GET /admin/airports" do
    it "renders a bounded airport index for administrators" do
      get admin_airports_path

      expect(response).to have_http_status(:ok)
      expect(inertia.component).to eq("Admin/Airports/Index")
      expect(inertia.props[:airports].first).to include(
        placeId: airport.place_id,
        iataCode: airport.iata_code,
        icaoCode: airport.icao_code
      )
      expect(inertia.props.dig(:navigation, :sections).first[:items].first[:current]).to be(true)
      expect(inertia.props.dig(:pagination, :currentPage)).to eq(1)
      expect(inertia.props.dig(:shell, :urls, :admin)).to eq(admin_root_path)
    end

    it "serves the next bounded page" do
      create_list(:airport, 26)

      get admin_airports_path(page: 2)

      expect(response).to have_http_status(:ok)
      expect(inertia.props.dig(:pagination, :currentPage)).to eq(2)
      expect(inertia.props[:airports].size).to eq(2)
    end

    context "when the user is a member" do
      let(:role) { "member" }

      it "redirects to the public home page" do
        get admin_airports_path

        expect(response).to redirect_to(root_path)
      end
    end

    context "without a session" do
      before { cookies[:user_session_token] = "invalid-session-cookie" }

      it "redirects to sign in" do
        get admin_airports_path

        expect(response).to redirect_to(sign_in_path)
      end
    end
  end

  describe "GET /admin/airports/:place_id/edit" do
    it "renders the airport edit page" do
      get edit_admin_airport_path(airport.place_id)

      expect(response).to have_http_status(:ok)
      expect(inertia.component).to eq("Admin/Airports/Edit")
      expect(inertia.props.dig(:airport, :placeId)).to eq(airport.place_id)
      expect(inertia.props.dig(:urls, :update)).to eq(admin_airport_path(airport.place_id))
    end
  end

  describe "PATCH /admin/airports/:place_id" do
    let(:params) do
      {
        airport: {
          name: "Updated Airport",
          municipality_name: "Updated City",
          country_code: "GB",
          region_code: "GB-ENG",
          time_zone: "Europe/London",
          operational_status: "closed",
          iata_code: "UPD",
          icao_code: "EUPD"
        }
      }
    end

    it "persists changes and redirects to the index" do
      patch admin_airport_path(airport.place_id), params: params

      expect(response).to redirect_to(admin_airports_path)
      expect(airport.reload.iata_code).to eq("UPD")
      expect(airport.place.reload.name).to eq("Updated Airport")
    end

    it "returns validation errors without partial persistence" do
      params[:airport][:time_zone] = "Not/A_Timezone"

      patch admin_airport_path(airport.place_id), params: params

      expect(response).to have_http_status(:unprocessable_content)
      expect(inertia.component).to eq("Admin/Airports/Edit")
      expect(inertia.props[:formErrors]).to be_present
      expect(airport.reload.iata_code).to eq("LHR")
      expect(airport.place.reload.name).to include("Airport")
    end

    context "when the user is a member" do
      let(:role) { "member" }

      it "does not change the airport" do
        patch admin_airport_path(airport.place_id), params: params

        expect(response).to redirect_to(root_path)
        expect(airport.reload.iata_code).to eq("LHR")
      end
    end
  end

  describe "DELETE /admin/airports/:place_id" do
    it "deletes an unlinked airport and its place" do
      place_id = airport.place_id

      delete admin_airport_path(place_id)

      expect(response).to redirect_to(admin_airports_path)
      expect(Airport.find_by(place_id:)).to be_nil
      expect(Place.find_by(id: place_id)).to be_nil
    end

    it "keeps an airport referenced by import provenance" do
      create(:imports_airport_source_link, airport:)

      delete admin_airport_path(airport.place_id)

      expect(response).to redirect_to(admin_airports_path)
      expect(airport.reload).to be_present
      expect(flash[:alert]).to be_present
    end
  end

  private

  def set_session_cookie(token)
    request = ActionDispatch::Request.new(Rails.application.env_config)
    jar = ActionDispatch::Cookies::CookieJar.build(request, {})
    jar.signed[:user_session_token] = token

    cookies[:user_session_token] = jar[:user_session_token]
  end
end
