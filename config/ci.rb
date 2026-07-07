# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"

  step "Frontend: Format", "npm run frontend:format"
  step "Frontend: Lint", "npm run frontend:lint"
  step "Frontend: Typecheck", "npm run frontend:typecheck"
  step "Frontend: Test", "npm run frontend:test"
  step "Frontend: Build", "npm run frontend:build"
  step "Frontend: Audit", "npm run frontend:audit"
  step "Frontend: Test build", "npm run frontend:build:test"

  step "Style: Ruby", "bin/rubocop"

  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

  step "Tests: RSpec", "bundle exec rspec"
  step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
