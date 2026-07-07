# frozen_string_literal: true

require "pathname"

class SecurityLoggingConfiguration
end

RSpec.describe SecurityLoggingConfiguration do
  let(:root) { Pathname(__dir__).join("../..").expand_path }

  it "filters sensitive request parameters and travel identifiers" do
    logging_config = root.join("config/initializers/filter_parameter_logging.rb").read
    expected_filters = %i[
      passw email secret token _key crypt salt certificate otp ssn cvv cvc
      authorization booking_reference raw_payload signed_id
    ]

    expected_filters.each do |filter|
      expect(logging_config).to include(":#{filter}")
    end
  end

  it "documents that examples must not contain realistic secrets" do
    security_policy = root.join("docs/QUALITY_SECURITY.md").read

    expect(security_policy).to include(
      "Do not add realistic secret, token, credential, or booking-reference examples"
    )
  end

  it "keeps docs and fixtures free of secret-like assignments" do
    scanned_paths = root.glob("docs/**/*") + root.glob("spec/fixtures/**/*")
    suspicious_assignment = /
      (password|secret|token|api[_-]?key|authorization|booking[_-]?reference|pnr)
      \s*[:=]\s*["']?[A-Za-z0-9][^\s"'`<>]*
    /ix

    offenders = scanned_paths.select(&:file?).filter_map do |path|
      path.relative_path_from(root).to_s if path.read.match?(suspicious_assignment)
    end

    expect(offenders).to be_empty, "Secret-like examples found in: #{offenders.join(', ')}"
  end
end
