require 'test_helper'

class Private::TransfersControllerTest < ActionDispatch::IntegrationTest

  attr_accessor :account1_txn, :account2_txn

  setup do
    ExternalAuthz.stubs(:configured?).returns(false)
    sign_in FactoryBot.create :user
    self.account1_txn = FactoryBot.create :transaction
    self.account2_txn = FactoryBot.create :transaction
  end

  test "rejects malformed form-encoded" do
    attrs = {
      amount: 100,
      from_account_id: account1_txn.account_id,
      to_account_id: account2_txn.account_id
    }
    post private_transfers_url, params: {transfer: attrs}, headers: authz_headers
    assert_response :bad_request
  end

  test "rejects malformed json" do
    attrs = {
      amount: 100,
      from_account_id: account1_txn.account_id,
      to_account_id: account2_txn.account_id
    }
    post private_transfers_url, params: attrs, as: :json, headers: authz_headers
    assert_response :bad_request
  end

  test "transfer" do
    data = {
      data: {
        type: 'transfer',
        attributes: {
          amount: 100,
          from_account_id: account1_txn.account_id,
          to_account_id: account2_txn.account_id
        }
      }
    }
    post private_transfers_url, params: data, as: :json, headers: authz_headers
    assert_response :no_content
  end

  test "transfer fails because account must be real" do
    account2_txn.account.destroy
    data = {
      data: {
        type: 'transfer',
        attributes: {
          amount: 100,
          from_account_id: account1_txn.account_id,
          to_account_id: account2_txn.account_id
        }
      }
    }
    post private_transfers_url, params: data, as: :json, headers: authz_headers
    assert_response :bad_request
  end

  test "transfer requires some jwt" do
    data = {
      data: {
        type: 'transfer',
        attributes: {
          amount: 100,
          from_account_id: account1_txn.account_id,
          to_account_id: account2_txn.account_id
        }
      }
    }
    post private_transfers_url, params: data, as: :json
    assert_response :unauthorized
  end

  test "transfer permitted by external authz" do
    ExternalAuthz.unstub(:configured?)
    ExternalAuthz.expects(:configured?).returns(true)
    Private::TransfersController.any_instance.
      expects(:external_authorize!).
      returns({})

    data = {
      data: {
        type: 'transfer',
        attributes: {
          amount: 100,
          from_account_id: account1_txn.account_id,
          to_account_id: account2_txn.account_id
        }
      }
    }
    post private_transfers_url, params: data, as: :json, headers: authz_headers
    assert_response :no_content
  end

  test "transfer denied by external authz" do
    ExternalAuthz.unstub(:configured?)
    ExternalAuthz.expects(:configured?).returns(true)
    Private::TransfersController.any_instance.
      expects(:external_authorize!).
      raises(ExternalAuthz::ExternalAuthorizationDenied.new('DENY', {}))

    data = {
      data: {
        type: 'transfer',
        attributes: {
          amount: 100,
          from_account_id: account1_txn.account_id,
          to_account_id: account2_txn.account_id
        }
      }
    }
    post private_transfers_url, params: data, as: :json, headers: authz_headers
    assert_response :forbidden
  end

  test "transfer denied by external authz with custom error message" do
    ExternalAuthz.unstub(:configured?)
    ExternalAuthz.expects(:configured?).returns(true)
    authz_result = {'statements' => [
      {'code' => 'denied-reason', 'payload' => 'Custom error message'}
    ]}
    Private::TransfersController.any_instance.
      expects(:external_authorize!).
      raises(ExternalAuthz::ExternalAuthorizationDenied.new('DENY', authz_result))

    data = {
      data: {
        type: 'transfer',
        attributes: {
          amount: 100,
          from_account_id: account1_txn.account_id,
          to_account_id: account2_txn.account_id
        }
      }
    }
    post private_transfers_url, params: data, as: :json, headers: authz_headers
    assert_response :forbidden
    json = JSON.parse(@response.body)

    assert_equal 'Custom error message',
                 json.try(:[], 'errors').try(:[], 0).try(:[], 'detail'),
                 "Expect json-api error with custom message. Got: #{json.inspect}"
  end

end
