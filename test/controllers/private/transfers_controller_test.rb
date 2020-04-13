require 'test_helper'

class Private::TransfersControllerTest < ActionDispatch::IntegrationTest

  attr_accessor :account1_txn, :account2_txn

  setup do
    self.account1_txn = FactoryBot.create :transaction
    self.account2_txn = FactoryBot.create :transaction
  end

  test "rejects malformed form-encoded" do
    attrs = {amount: 100, from_account_id: account1_txn.account_id, to_account_id: account2_txn.account_id}
    post private_transfers_url, params: {transfer: attrs}
    assert_response :bad_request
  end

  test "rejects malformed json" do
    attrs = {amount: 100, from_account_id: account1_txn.account_id, to_account_id: account2_txn.account_id}
    post private_transfers_url, params: attrs, as: :json
    assert_response :bad_request
  end

  test "transfer" do
    data = {data: {type: 'transfer', attributes: {amount: 100, from_account_id: account1_txn.account_id, to_account_id: account2_txn.account_id}}}
    post private_transfers_url, params: data, as: :json
    assert_response :created
  end

  test "transfer fails because account must be real" do
    account2_txn.account.destroy
    data = {data: {type: 'transfer', attributes: {amount: 100, from_account_id: account1_txn.account_id, to_account_id: account2_txn.account_id}}}
    post private_transfers_url, params: data, as: :json
    assert_response :bad_request
  end
end
