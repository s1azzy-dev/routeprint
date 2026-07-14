require "rails_helper"

RSpec.describe "Admin airport imports", type: :request do
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
  let!(:source) do
    create(
      :imports_source,
      config: { "source_url" => "https://example.test/airports.csv", "parser_version" => "1" }
    )
  end

  before { set_session_cookie(raw_token) }

  describe "GET /admin/imports/airports" do
    let!(:older_run) do
      create(
        :imports_run,
        source:,
        params: { "source_url" => "https://example.test/old.csv", "parser_version" => "1", "secret" => "hidden" },
        total_item_count: 10,
        completed_item_count: 8,
        failed_item_count: 1,
        issue_count: 1,
        created_at: 2.hours.ago
      )
    end
    let!(:newer_run) do
      create(
        :imports_run,
        source:,
        status: "succeeded",
        params: { "source_url" => "https://example.test/new.csv", "parser_version" => "2", "secret" => "hidden" },
        total_item_count: 1,
        completed_item_count: 1,
        created_at: 1.hour.ago
      )
    end

    it "renders newest airport runs with safe props and Imports navigation" do
      get admin_imports_airports_path

      expect_index_page
    end

    it "serves a bounded later page" do
      stub_const("Admin::Imports::AirportsController::PAGE_SIZE", 1)

      get admin_imports_airports_path(page: 2)

      expect(response).to have_http_status(:ok)
      expect(inertia.props[:runs].map { |run| run[:id] }).to eq([ older_run.id ])
      expect(inertia.props.dig(:pagination, :currentPage)).to eq(2)
    end

    context "when the user is a member" do
      let(:role) { "member" }

      it "redirects to the public home page" do
        get admin_imports_airports_path

        expect(response).to redirect_to(root_path)
      end
    end

    context "without a session" do
      before { cookies[:user_session_token] = "invalid-session-cookie" }

      it "redirects to sign in" do
        get admin_imports_airports_path

        expect(response).to redirect_to(sign_in_path)
      end
    end
  end

  describe "POST /admin/imports/airports" do
    include ActiveJob::TestHelper

    around do |example|
      previous_adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :test
      clear_enqueued_jobs
      example.run
    ensure
      clear_enqueued_jobs
      ActiveJob::Base.queue_adapter = previous_adapter
    end

    it "starts a full airport import for the current administrator" do
      expect {
        post admin_imports_airports_path
      }.to change(Imports::Run, :count).by(1)

      expect_started_run
    end

    it "does not create a second run while one is active" do
      create(:imports_run, source:, status: "running")

      expect {
        post admin_imports_airports_path
      }.not_to change(Imports::Run, :count)

      expect(response).to redirect_to(admin_imports_airports_path)
      expect(flash[:alert]).to be_present
    end

    it "does not create a run when the source is disabled" do
      source.update!(enabled: false)

      expect {
        post admin_imports_airports_path
      }.not_to change(Imports::Run, :count)

      expect(response).to redirect_to(admin_imports_airports_path)
      expect(flash[:alert]).to be_present
    end

    context "when the user is a member" do
      let(:role) { "member" }

      it "redirects without creating a run" do
        expect {
          post admin_imports_airports_path
        }.not_to change(Imports::Run, :count)

        expect(response).to redirect_to(root_path)
      end
    end

    context "without a session" do
      before { cookies[:user_session_token] = "invalid-session-cookie" }

      it "redirects to sign in without creating a run" do
        expect {
          post admin_imports_airports_path
        }.not_to change(Imports::Run, :count)

        expect(response).to redirect_to(sign_in_path)
      end
    end
  end

  private

  def expect_index_page
    expect(response).to have_http_status(:ok)
    expect(inertia.component).to eq("Admin/Imports/Airports/Index")
    expect(inertia.props[:runs].map { |run| run[:id] }).to eq([ newer_run.id, older_run.id ])
    expect(inertia.props[:runs].first).to include(
      sourceKey: source.key,
      mode: "full",
      status: "succeeded",
      totalCount: 1,
      completedCount: 1
    )
    expect(inertia.props[:runs].first).not_to include(:secret, :params)
    expect(inertia.props.dig(:copy, :actions, :start)).to be_present
    expect_import_navigation
  end

  def expect_import_navigation
    expect(inertia.props.dig(:navigation, :sections)).to include(
      hash_including(
        key: "imports",
        label: "Imports",
        items: include(hash_including(key: "import_airports", current: true))
      )
    )
  end

  def expect_started_run
    run = Imports::Run.order(:id).last

    expect(response).to redirect_to(admin_imports_airports_path)
    expect(run).to have_attributes(
      source:,
      initiated_by: user,
      mode: "full",
      status: "queued",
      params: include("source_url" => "https://ourairports.com/data/airports.csv", "parser_version" => "1")
    )
    expect(flash[:notice]).to be_present
  end

  def set_session_cookie(token)
    request = ActionDispatch::Request.new(Rails.application.env_config)
    jar = ActionDispatch::Cookies::CookieJar.build(request, {})
    jar.signed[:user_session_token] = token

    cookies[:user_session_token] = jar[:user_session_token]
  end
end
