# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin country imports", type: :request do
  let(:raw_token) { SecureRandom.urlsafe_base64(48) }
  let(:user) { create(:user, role:) }
  let(:role) { "admin" }
  let(:settings) { ApplicationConfig.config.imports.countries }
  let!(:session) { create(:user_session, user:, token_digest: UserSession.digest_token(raw_token)) }
  let!(:country_source) { create(:imports_source, key: settings.source_key, provider_key: "routeprint", dataset_key: "country_catalog", target_kind: "country") }

  before { set_session_cookie(raw_token) }

  describe "GET /admin/imports/countries" do
    let!(:run) do
      create(
        :imports_run,
        source: country_source,
        params: { "ourairports_source_url" => "https://example.test/countries.csv", "cldr_release" => "48.2.1", "secret" => "hidden" }
      )
    end

    it "shows country source history with only allowlisted parameters" do
      get admin_imports_countries_path

      expect(response).to have_http_status(:ok)
      expect(inertia.component).to eq("Admin/Imports/Countries/Index")
      expect(inertia.props[:runs]).to contain_exactly(hash_including(id: run.id, sourceKey: country_source.key))
      expect(inertia.props[:runs].first[:parameters]).not_to have_key(:secret)
      expect(inertia.props.dig(:navigation, :sections)).to include(
        hash_including(items: include(hash_including(key: "import_countries", current: true)))
      )
    end

    context "when the user is a member" do
      let(:role) { "member" }

      it "redirects to the public home page" do
        get admin_imports_countries_path

        expect(response).to redirect_to(root_path)
      end
    end

    context "without a session" do
      before { cookies[:user_session_token] = "invalid-session-cookie" }

      it "redirects to sign in" do
        get admin_imports_countries_path

        expect(response).to redirect_to(sign_in_path)
      end
    end
  end

  describe "POST /admin/imports/countries" do
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

    it "starts one composite catalog run for the current administrator" do
      expect { post admin_imports_countries_path }.to change(Imports::Run, :count).by(1)

      expect(response).to redirect_to(admin_imports_countries_path)
      expect(Imports::Run.last).to have_attributes(initiated_by: user, status: "queued")
      expect(Imports::Run.last.items).to have_attributes(count: 1)
    end

    context "when the user is a member" do
      let(:role) { "member" }

      it "redirects without starting source runs" do
        expect { post admin_imports_countries_path }.not_to change(Imports::Run, :count)

        expect(response).to redirect_to(root_path)
      end
    end

    context "without a session" do
      before { cookies[:user_session_token] = "invalid-session-cookie" }

      it "redirects to sign in without starting source runs" do
        expect { post admin_imports_countries_path }.not_to change(Imports::Run, :count)

        expect(response).to redirect_to(sign_in_path)
      end
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
