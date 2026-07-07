# frozen_string_literal: true

require "json"
require "pathname"

class FrontendFoundationConfiguration
end

RSpec.describe FrontendFoundationConfiguration do
  let(:root) { Pathname(__dir__).join("../..").expand_path }
  let(:package) { JSON.parse(root.join("package.json").read) }
  let(:scripts) { package.fetch("scripts") }

  it "pins the approved frontend runtime and build dependencies" do
    expect(package.fetch("name")).to eq("routeprint")
    expect(package.fetch("dependencies")).to include(
      "@inertiajs/react" => "3.6.0",
      "react" => "19.2.7",
      "react-dom" => "19.2.7",
    )
    expect(package.fetch("devDependencies")).to include(
      "@tailwindcss/vite" => "4.3.2",
      "typescript" => "6.0.3",
      "vite" => "8.1.3",
      "vitest" => "4.1.9",
    )
  end

  it "provides deterministic frontend quality scripts" do
    expect(scripts).to include(
      "frontend:audit" => "npm audit --audit-level=high",
      "frontend:format" => 'prettier --check --log-level warn "app/frontend/**/*.{ts,tsx,css}" vite.config.ts eslint.config.mjs package.json tsconfig.json components.json',
      "frontend:lint" => "eslint . --quiet",
      "frontend:test" => "vitest run --coverage --reporter=minimal --passWithNoTests",
      "frontend:typecheck" => "tsc --noEmit --pretty false"
    )
  end

  it "runs every frontend quality gate through the verification script" do
    expect(scripts.fetch("frontend:verify")).to include(
      "frontend:format",
      "frontend:lint",
      "frontend:typecheck",
      "frontend:test",
      "frontend:build",
      "frontend:audit",
    )
  end

  it "uses strict TypeScript and the shared Vitest setup" do
    expect(root.join("tsconfig.json").read).to include('"strict": true', '"noEmit": true')
    expect(root.join("vite.config.ts").read).to include("react()", "tailwindcss()", 'setupFiles: ["./test/setup.ts"]')
    expect(root.join("app/frontend/test/setup.ts")).to exist
  end

  it "renders through the Inertia layout and Routeprint page" do
    layout = root.join("app/views/layouts/inertia.html.erb").read
    routes = root.join("config/routes.rb").read
    controller = root.join("app/controllers/home_controller.rb").read

    expect(layout).to include("vite_react_refresh_tag", 'vite_typescript_tag "application.tsx"')
    expect(routes).to include('root "home#show"')
    expect(controller).to include('render inertia: "Home/Show"')
    expect(root.join("app/frontend/pages/Home/Show.tsx")).to exist
  end

  it "provides RTK-backed agent commands for compact feedback" do
    makefile = root.join("Makefile").read

    expect(makefile).to include(
      "agent-rspec:",
      "ROUTEPRINT_SKIP_SIMPLECOV=1 RAILS_ENV=test rtk rspec $(SPEC)",
      "agent-frontend-test:",
      "rtk vitest run --coverage --reporter=minimal --passWithNoTests",
      "agent-verify-fast: frontend-install",
    )
  end
end
