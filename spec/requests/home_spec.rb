require "rails_helper"

RSpec.describe "Home" do
  it "renders the Routeprint Inertia shell" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(inertia.component).to eq("Home/Show")
    expect(inertia.props[:appName]).to eq("Routeprint")
  end
end
