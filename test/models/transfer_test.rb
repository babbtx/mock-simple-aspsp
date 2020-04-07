require 'test_helper'

class TransferTest < ActiveSupport::TestCase
  test "ids must be present" do
    transfer = Transfer.new amount: 100
    assert !transfer.valid?
    assert_equal "can't be blank", transfer.errors[:from_account_id].first
    assert_equal "can't be blank", transfer.errors[:to_account_id].first
  end

  test "accounts must be real" do
    account1 = FactoryBot.create :account
    account2 = FactoryBot.create :account
    account2.destroy
    transfer = Transfer.new amount: 100, from_account_id: account1.id, to_account_id: account2.id
    assert !transfer.valid?
    assert_equal "not found", transfer.errors[:to_account_id].first
  end

  test "transfer" do
    account1_txn = FactoryBot.create :transaction
    account2_txn = FactoryBot.create :transaction
    transfer = Transfer.create amount: 100, from_account_id: account1_txn.account_id, to_account_id: account2_txn.account_id
    assert transfer.errors.empty?
    assert_equal account1_txn.balance - Monetize.parse!(100, account1_txn.account.currency),
                 account1_txn.account.reload.transactions.newest_first.first.balance
    assert_equal account2_txn.balance + Monetize.parse!(100, account1_txn.account.currency),
                 account2_txn.account.reload.transactions.newest_first.first.balance
  end
end
