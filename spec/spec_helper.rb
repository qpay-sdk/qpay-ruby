# frozen_string_literal: true

require "webmock/rspec"
require "json"
require "qpay"

WebMock.disable_net_connect!

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.order = :random
  Kernel.srand config.seed
end

# Helper to build a default QPay::Config for tests
def build_test_config
  QPay::Config.new(
    base_url: "https://merchant.qpay.mn",
    username: "TEST_USER",
    password: "TEST_PASS",
    invoice_code: "TEST_INVOICE_CODE",
    callback_url: "https://example.com/callback"
  )
end

# Helper to build a token response JSON body
def token_response_body
  {
    "token_type" => "Bearer",
    "refresh_expires_in" => 1_800_000,
    "refresh_token" => "test-refresh-token",
    "access_token" => "test-access-token",
    "expires_in" => (Time.now.to_i + 3600),
    "scope" => "default",
    "not-before-policy" => 0,
    "session_state" => "abc123"
  }.to_json
end

# Helper to stub the auth token endpoint so all authenticated requests succeed
def stub_auth_token
  stub_request(:post, "https://merchant.qpay.mn/v2/auth/token")
    .to_return(
      status: 200,
      body: token_response_body,
      headers: { "Content-Type" => "application/json" }
    )
end
