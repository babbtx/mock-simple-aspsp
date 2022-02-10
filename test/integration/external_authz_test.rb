require 'test_helper'

class ExternalAuthzTest < ActionDispatch::IntegrationTest

  client_id = SecureRandom.uuid
  client_secret = SecureRandom.base64(32)
  token_url = "http://example.com/as/token"
  env_id = SecureRandom.uuid
  decision_url = "https://example.com/api/v1/environments/#{env_id}/decisionEndpoints/etc"
  basic_authz = "Basic #{Base64.urlsafe_encode64([client_id, client_secret].join(':'))}"

  config = {
    url: decision_url,
    token_url: token_url,
    client_id: client_id,
    client_secret: client_secret,
  }

  setup do
    sign_in FactoryBot.create :user
  end

  test "external authz config via request" do
    account = FactoryBot.create :account, owner: @current_user

    expected_authz_request = {
      parameters: {
        account: account.id.to_s,
        Application: 'TreeQuote',
        'TreeQuote.Controller': 'accounts',
        'TreeQuote.Action': 'show',
      },
      userContext: {
        environment: { id: env_id },
        user: { id: @current_user.uuid }
      }
    }

    token_response = {
      "access_token": "token",
      "token_type": "Bearer",
      "expires_in": 3600
    }

    permit_response = {
      decision: 'PERMIT'
    }

    stub_request(:post, token_url)
      .with(headers: {authorization: basic_authz})
      .to_return(status: 200, headers: {'content-type': 'application/json'}, body: token_response.to_json)

    stub_request(:post, decision_url)
      .with(headers: {authorization: "Bearer token"}, body: expected_authz_request.to_json)
      .to_return(status: 200, body: permit_response.to_json)

    get account_url(account), as: :json, headers: authz_headers.merge('X-PingOneAuthorize-Config': config.to_json)
    assert_response :success
  end

  test "external authz disabled on bad header value" do
    account = FactoryBot.create :account, owner: @current_user
    get account_url(account), as: :json, headers: authz_headers.merge('X-PingOneAuthorize-Config': "blah")
    assert_response :success
    assert_not_requested(:post, token_url)
    assert_not_requested(:post, decision_url)
  end

  test "external authz disabled on no header value" do
    account = FactoryBot.create :account, owner: @current_user
    get account_url(account), as: :json, headers: authz_headers
    assert_response :success
    assert_not_requested(:post, token_url)
    assert_not_requested(:post, decision_url)
  end

end
