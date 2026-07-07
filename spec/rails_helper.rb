ENV["RAILS_ENV"] = "test"

require "spec_helper"
require File.expand_path("../config/environment", __dir__)

abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "active_support/testing/time_helpers"
require "factory_bot_rails"
require "inertia_rails/rspec"
require "pundit/rspec"
require "shoulda/matchers"

Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |file| require file }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => error
  abort error.to_s.strip
end

RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers
  config.fixture_paths = [ Rails.root.join("spec/fixtures") ]
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.use_transactional_fixtures = true
  config.include FactoryBot::Syntax::Methods
  config.before do
    Rails.cache.clear
  end

  config.before(:each, type: :system) do
    driven_by(:rack_test)
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
