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

  test "gets transaction after fromBookingDateTime" do
    now = DateTime.now
    txn = FactoryBot.create :transaction, booked_at: now
    older_txn = FactoryBot.create :transaction, account: txn.account, booked_at: now.ago(2)
    assert_equal 2, Transaction.for_account(txn.account).count

    sign_in txn.account.owner
    get transactions_url('fromBookingDateTime': now.ago(1).iso8601),
        as: :json, headers: authz_headers
    assert_response :success

    json = JSON.parse(@response.body)

    assert json.has_key?('Data')
    assert_equal 1, json['Data']['Transaction'].size
    assert_equal txn.id, json['Data']['Transaction'][0]['TransactionId']
  end

  test "gets transaction before toBookingDateTime" do
    now = DateTime.now
    txn = FactoryBot.create :transaction, booked_at: now
    older_txn = FactoryBot.create :transaction, account: txn.account, booked_at: now.ago(2)
    assert_equal 2, Transaction.for_account(txn.account).count

    sign_in txn.account.owner
    get transactions_url('toBookingDateTime': now.ago(1).iso8601),
        as: :json, headers: authz_headers
    assert_response :success

    json = JSON.parse(@response.body)

    assert json.has_key?('Data')
    assert_equal 1, json['Data']['Transaction'].size
    assert_equal older_txn.id, json['Data']['Transaction'][0]['TransactionId']
  end

  test "gets transaction in range" do
    now = DateTime.now
    account = FactoryBot.create :account
    txn1 = FactoryBot.create :transaction, account: account, booked_at: now.ago(5)
    txn2 = FactoryBot.create :transaction, account: account, booked_at: now.ago(3)
    txn3 = FactoryBot.create :transaction, account: account, booked_at: now.ago(1)
    assert_equal 3, Transaction.for_account(account).count

    sign_in account.owner
    get transactions_url('fromBookingDateTime': now.ago(4).iso8601, 'toBookingDateTime': now.ago(2).iso8601),
        as: :json, headers: authz_headers
    assert_response :success

    json = JSON.parse(@response.body)

    assert json.has_key?('Data')
    assert_equal 1, json['Data']['Transaction'].size
    assert_equal txn2.id, json['Data']['Transaction'][0]['TransactionId']
  end

  test "gets nothing in range" do
    now = DateTime.now
    older_txn = FactoryBot.create :transaction, booked_at: now.ago(2)

    sign_in older_txn.account.owner
    get transactions_url('fromBookingDateTime': now.ago(1).iso8601),
        as: :json, headers: authz_headers
    assert_response :success

    json = JSON.parse(@response.body)

    assert json.has_key?('Data')
    assert_equal 0, json['Data']['Transaction'].size
  end

  test "400 error on bad date format" do
    txn = FactoryBot.create :transaction
    sign_in txn.account.owner
    get transactions_url('fromBookingDateTime': 'jello'), as: :json, headers: authz_headers
    assert_response 400
  end
end
