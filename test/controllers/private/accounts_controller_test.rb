require 'test_helper'

class Private::AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in FactoryBot.create :user
  end

  test "get single account returns owner uuid" do
    account = FactoryBot.create :account
    get private_account_url(account.id), as: :json, headers: authz_headers
    assert_response :success

    json = JSON.parse(@response.body)
    assert json.has_key?('data')
    assert_equal account.id.to_s, json['data']['id']
    assert_equal account.owner.uuid, json['data']['attributes']['owner_uuid']
  end

  test "get accounts for current user" do
    account = FactoryBot.create :account
    sign_in account.owner
    get private_accounts_url, as: :json, headers: authz_headers
    assert_response :success

    json = JSON.parse(@response.body)
    assert json.has_key?('data')
    assert_equal 1, json['data'].size
    assert_equal account.id.to_s, json['data'][0]['id']
  end

  test "get accounts for user in url path params" do
    account = FactoryBot.create :account
    get private_user_accounts_url(account.owner.uuid), as: :json, headers: authz_headers
    assert_response :success

    json = JSON.parse(@response.body)
    assert json.has_key?('data')
    assert_equal 1, json['data'].size
    assert_equal account.id.to_s, json['data'][0]['id']
  end
end
