# == Schema Information
#
# Table name: transactions
#
#  id               :bigint(8)        not null, primary key
#  account_id       :bigint(8)
#  amount_cents     :integer          default(0), not null
#  amount_currency  :string           not null
#  booked_at        :datetime         not null
#  credit_or_debit  :integer          not null
#  description      :string
#  balance_cents    :integer          default(0), not null
#  balance_currency :string           not null
#  merchant_name    :string
#  merchant_code    :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

require 'test_helper'

class TransactionTest < ActiveSupport::TestCase

  attr_accessor :account

  setup do
    self.account = FactoryBot.create :account
  end

  test "adds to balance" do
    tx1 = account.transactions.create amount: Money.new(1, 'USD'),
                                      booked_at: 1.week.ago,
                                      credit_or_debit: Transaction::CREDIT
    assert_equal Money.new(1, 'USD'), tx1.balance

    tx3 = account.transactions.create amount: Money.new(3, 'USD'),
                                      booked_at: 1.week.from_now,
                                      credit_or_debit: Transaction::CREDIT
    assert_equal Money.new(4, 'USD'), tx3.balance

    # this one inserted in between
    # should be based on tx1 and not tx3
    tx2 = account.transactions.create amount: Money.new(2, 'USD'),
                                      booked_at: 1.day.ago,
                                      credit_or_debit: Transaction::CREDIT
    assert_equal Money.new(3, 'USD'), tx2.balance
  end

  test "subtracts from balance" do
    tx1 = account.transactions.create amount: Money.new(10, 'USD'),
                                      booked_at: 1.week.ago,
                                      credit_or_debit: Transaction::CREDIT
    assert_equal Money.new(10, 'USD'), tx1.balance

    tx2 = account.transactions.create amount: Money.new(1, 'USD'),
                                      booked_at: 1.day.ago,
                                      credit_or_debit: Transaction::DEBIT
    assert_equal Money.new(9, 'USD'), tx2.balance
  end

  test "updates balances after transaction" do
    tx1 = account.transactions.create amount: Money.new(1, 'USD'),
                                      booked_at: 1.week.ago,
                                      credit_or_debit: Transaction::CREDIT
    assert_equal Money.new(1, 'USD'), tx1.balance

    tx3 = account.transactions.create amount: Money.new(3, 'USD'),
                                      booked_at: 1.week.from_now,
                                      credit_or_debit: Transaction::CREDIT
    assert_equal Money.new(4, 'USD'), tx3.balance

    # this one inserted in between
    tx2 = account.transactions.create amount: Money.new(2, 'USD'),
                                      booked_at: 1.day.ago,
                                      credit_or_debit: Transaction::CREDIT
    assert_equal Money.new(3, 'USD'), tx2.balance

    # now reload tx3 and make sure it's updated
    tx3 = Transaction.find(tx3.id)
    assert_equal Money.new(6, 'USD'), tx3.balance
  end

  test "association to account owner" do
    # just checking that i did this right
    tx = FactoryBot.create :transaction, account: account
    assert_equal account.owner, tx.account_owner
  end

  test "scope for user" do
    FactoryBot.create :transaction, account: account
    account2 = FactoryBot.create :account, owner: account.owner
    FactoryBot.create :transaction, account: account2
    assert_equal 2, Transaction.for_user(account.owner).size
  end
end
