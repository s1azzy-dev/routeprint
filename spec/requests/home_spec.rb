require "rails_helper"

RSpec.describe "Home" do
  it "renders the Routeprint Inertia shell" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(inertia.component).to eq("Home/Show")
    expect(inertia.props.dig(:shell, :authenticated)).to be(false)
    expect(inertia.props.dig(:shell, :urls, :signIn)).to eq(sign_in_path)
    expect(inertia.props.dig(:shell, :urls, :signOut)).to eq(sign_out_path)
  end
end
