require "rails_helper"

RSpec.describe "Member airport selection", type: :request do
  it "redirects a guest" do
    get "/airports/search", params: { query: "LH" }
    expect(response).to redirect_to(sign_in_path)
  end

  it "returns distinct code collisions and a closed label with safe fields" do
    create(:airport)
    create(:airport, operational_status: "closed")
    authenticate_member(create(:user))
    get "/airports/search", params: { query: "lhr" }
    rows = response.parsed_body.fetch("airports")
    expect(rows.size).to eq(2)
    expect(rows.map { |row| row["id"] }.uniq.size).to eq(2)
    expect(rows.last.keys).to contain_exactly("id", "name", "iataCode", "icaoCode", "countryCode", "closed")
    expect(rows.pluck("closed")).to include(true)
  end

  it "supports localized names, enforces limits and rejects invalid queries" do
    airport = create(:airport)
    create(:place_name, place: airport.place, locale: "ru", name: "Хитроу")
    authenticate_member(create(:user, locale: "ru"))
    get "/airports/search", params: { query: "хит" }
    expect(response.parsed_body.dig("airports", 0, "name")).to eq("Хитроу")
    get "/airports/search", params: { query: "a" }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "caps name search results at twenty airports" do
    create_list(:airport, 21)
    authenticate_member(create(:user))
    get "/airports/search", params: { query: "Airport" }
    expect(response.parsed_body.fetch("airports").size).to eq(20)
  end
end
