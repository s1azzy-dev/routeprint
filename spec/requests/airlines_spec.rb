require "rails_helper"

RSpec.describe "Airline catalog selection", type: :request do
  describe "GET /airlines/search" do
    it "redirects guests without returning catalog data" do
      get "/airlines/search", params: { query: "Air" }

      expect(response).to redirect_to(sign_in_path)
      expect(response.body).not_to include("Airline")
    end

    it "returns an allowlisted localized picker payload to an authenticated user" do
      user, airline = localized_airline
      sign_in(user)

      get "/airlines/search", params: { query: "Example" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/json")
      expect(response.parsed_body).to eq(expected_picker_payload(airline))
    end

    it "marks pending and inactive results without exposing protected evidence" do
      airline = create(:airline, :inactive, name: "Pending Historical")
      create(:airline_submission, airline:)
      sign_in(create(:user))

      get "/airlines/search", params: { query: "Pending" }

      row = response.parsed_body.fetch("airlines").first
      expect(row).to include("inactive" => true, "pending" => true)
      expect(row.keys).to contain_exactly("id", "name", "preferredCode", "countryName", "inactive", "pending")
    end

    it "uses the requested flight date when choosing the preferred code" do
      airline = create(:airline, :approved, name: "Historical Codes")
      create(:airline_designator, airline:, system: "iata", code: "N1", valid_from: Date.new(2000, 1, 1))
      create(:airline_designator, airline:, system: "icao", code: "OLD", valid_until: Date.new(1999, 12, 31))
      sign_in(create(:user))

      get "/airlines/search", params: { query: "Historical", flight_date: "1995-06-01" }

      expect(response.parsed_body.dig("airlines", 0, "preferredCode")).to eq("OLD")
    end

    it "rejects malformed search input" do
      sign_in(create(:user))

      get "/airlines/search", params: { query: "Air", flight_date: "not-a-date" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.keys).to eq([ "errors" ])
    end
  end

  describe "POST /airlines" do
    let(:params) do
      {
        airline: {
          name: "Example Air",
          code: "E1",
          country_id: nil,
          confirmed: true
        }
      }
    end

    it "redirects guests without creating catalog data" do
      expect { post "/airlines", params: }.not_to change(Airline, :count)

      expect(response).to redirect_to(sign_in_path)
    end

    it "creates a pending candidate for the authenticated submitter" do
      user = create(:user)
      sign_in(user)

      expect { post "/airlines", params:, as: :json }.to change(Airline, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("reused" => false)
      expect(response.parsed_body.fetch("airline")).to include(
        "name" => "Example Air",
        "preferredCode" => "E1",
        "pending" => true
      )
      expect(Airline.last.submission.submitted_by_user).to eq(user)
    end

    it "ignores lifecycle fields outside the submission allowlist" do
      sign_in(create(:user))
      params[:airline].merge!(review_status: "approved", operational_status: "active")

      post "/airlines", params:, as: :json

      expect(Airline.last).to have_attributes(review_status: "pending", operational_status: "unknown")
    end

    it "returns actionable validation fields without partial data" do
      sign_in(create(:user))
      params[:airline][:code] = "INVALID"

      expect { post "/airlines", params:, as: :json }.not_to change(Airline, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors").keys).to include("code")
    end
  end

  def sign_in(user)
    raw_token = SecureRandom.urlsafe_base64(48)
    create(:user_session, user:, token_digest: UserSession.digest_token(raw_token))
    request = ActionDispatch::Request.new(Rails.application.env_config)
    jar = ActionDispatch::Cookies::CookieJar.build(request, {})
    jar.signed[:user_session_token] = raw_token
    cookies[:user_session_token] = jar[:user_session_token]
  end

  def localized_airline
    user = create(:user, locale: "ru")
    country = create(:country, name: "United Kingdom")
    create(:country_name, country:, locale: "ru", name: "Великобритания")
    airline = create(:airline, :approved, name: "Example Air", country:)
    create(:airline_designator, airline:, system: "icao", code: "EXA")
    create(:airline_designator, airline:, system: "iata", code: "E1")

    [ user, airline ]
  end

  def expected_picker_payload(airline)
    {
      "airlines" => [
        {
          "id" => airline.id,
          "name" => "Example Air",
          "preferredCode" => "E1",
          "countryName" => "Великобритания",
          "inactive" => false,
          "pending" => false
        }
      ]
    }
  end
end
