if ENV["ROUTEPRINT_SKIP_SIMPLECOV"] != "1" && Dir.glob(File.expand_path("**/*_spec.rb", __dir__)).any?
  require "simplecov"

  SimpleCov.start "rails" do
    minimum_coverage 90
    add_filter "/bin/"
    add_filter "/config/"
    add_filter "/db/"
    add_filter "/spec/"
    add_filter "/app/helpers/application_helper.rb"
    add_filter "/app/jobs/application_job.rb"
    add_filter "/app/models/application_record.rb"
    add_filter "/app/controllers/application_controller.rb"
    add_filter "/app/mailers/application_mailer.rb"
    add_filter "/app/contracts/application_contract.rb"
    add_filter "/app/interactors/application_interactor.rb"
    add_filter "/app/policies/application_policy.rb"
  end
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = "tmp/rspec/examples.txt"
  config.disable_monkey_patching!

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
