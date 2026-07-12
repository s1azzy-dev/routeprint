if ENV["ROUTEPRINT_SKIP_SIMPLECOV"] != "1" && Dir.glob(File.expand_path("**/*_spec.rb", __dir__)).any?
  require "simplecov"

  SimpleCov.start "rails" do
    minimum_coverage 90
    skip "/bin/"
    skip "/config/"
    skip "/db/"
    skip "/spec/"
    skip "/app/helpers/application_helper.rb"
    skip "/app/jobs/application_job.rb"
    skip "/app/models/application_record.rb"
    skip "/app/controllers/application_controller.rb"
    skip "/app/mailers/application_mailer.rb"
    skip "/app/contracts/application_contract.rb"
    skip "/app/interactors/application_interactor.rb"
    skip "/app/policies/application_policy.rb"
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
