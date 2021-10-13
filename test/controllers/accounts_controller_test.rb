require 'test_helper'

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    ExternalAuthz.stubs(:configured?).returns(false)
  end

  test "OpenBanking Accounts format bulk" do
    account = FactoryBot.create :account
    sign_in account.owner
    get accounts_url, as: :json, headers: authz_headers
    assert_response :success

    json = JSON.parse(@response.body)

    assert json.has_key?('Links')
    assert_equal accounts_url, json['Links']['Self']

    assert json.has_key?('Meta')
    assert_equal 1, json['Meta']['TotalPages']

    assert json.has_key?('Data')
    assert_equal 1, json['Data']['Account'].size
    assert_equal account.id, json['Data']['Account'][0]['AccountId']
    assert_equal account.account_type, json['Data']['Account'][0]['AccountType']
    assert_equal account.account_subtype, json['Data']['Account'][0]['AccountSubType']
    assert_equal account.scheme_name, json['Data']['Account'][0]['Account']['SchemeName']
    assert_equal account.identification, json['Data']['Account'][0]['Account']['Identification']
  end
end
