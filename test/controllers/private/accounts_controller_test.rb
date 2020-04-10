require 'test_helper'

class Private::AccountsControllerTest < ActionDispatch::IntegrationTest
  test "account returns owner uuid" do
    account = FactoryBot.create :account
    get private_account_url(account.id), as: :json
    assert_response :success

    json = JSON.parse(@response.body)
    assert json.has_key?('data')
    assert_equal account.id.to_s, json['data']['id']
    assert_equal account.owner.uuid, json['data']['attributes']['owner_uuid']
  end
end
