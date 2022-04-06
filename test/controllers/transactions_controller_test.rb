require 'test_helper'

class TransactionsControllerTest < ActionDispatch::IntegrationTest
  test "OpenBanking Transactions format bulk" do
    txn = FactoryBot.create :transaction
    sign_in txn.account.owner
    get transactions_url, as: :json, headers: authz_headers
    assert_response :success

    json = JSON.parse(@response.body)

    assert json.has_key?('Links')
    assert_equal transactions_url, json['Links']['Self']

    assert json.has_key?('Meta')
    assert_equal 1, json['Meta']['TotalPages']

    assert json.has_key?('Data')
    assert_equal 1, json['Data']['Transaction'].size
    assert_equal txn.account.id, json['Data']['Transaction'][0]['AccountId']
    assert_equal txn.id, json['Data']['Transaction'][0]['TransactionId']
    assert_equal txn.amount.format(symbol: false), json['Data']['Transaction'][0]['Amount']['Amount']
    assert_equal txn.booked_at.utc.to_s, DateTime.iso8601(json['Data']['Transaction'][0]['BookingDateTime']).utc.to_s
  end
end
