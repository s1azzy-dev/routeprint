# frozen_string_literal: true

module InertiaPropsHelpers
  def expect_inertia_runtime_document!
    expect(response.body).to include("Routeprint needs JavaScript")
    expect(response.body).to include('type="module"')
  end

  def sensitive_prop_keys
    %w[
      booking_reference
      credential
      credentials
      current_user
      identity
      raw_payload
      reset_token
      seat
      session
      source_payload
      token
      user
    ]
  end
end

RSpec.configure do |config|
  config.include InertiaPropsHelpers, type: :request
end
