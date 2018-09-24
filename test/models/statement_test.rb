# == Schema Information
#
# Table name: statements
#
#  id                       :bigint(8)        not null, primary key
#  account_id               :bigint(8)
#  starting_at              :datetime         not null
#  ending_at                :datetime         not null
#  starting_amount_cents    :integer
#  starting_amount_currency :string
#  ending_amount_cents      :integer          not null
#  ending_amount_currency   :string           not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#

require 'test_helper'

class StatementTest < ActiveSupport::TestCase

  attr_accessor :account

  setup do
    self.account = FactoryBot.create :account
  end

  test "finds transactions" do
    tx1 = FactoryBot.create :transaction, account: account, amount: Money.new(1), credit_or_debit: Transaction::CREDIT, booked_at: 2.days.ago
    tx2 = FactoryBot.create :transaction, account: account, amount: Money.new(1), credit_or_debit: Transaction::CREDIT, booked_at: 1.days.ago
    statement = Statement.new account: account, starting_at: 3.days.ago, ending_at: DateTime.now
    assert_includes statement.transactions, tx1
    assert_includes statement.transactions, tx2
  end

  test "calculates starting amount for credit" do
    FactoryBot.create :transaction, account: account, amount: Money.new(1), credit_or_debit: Transaction::CREDIT, booked_at: 2.days.ago
    statement = Statement.create account: account, starting_at: 3.days.ago, ending_at: DateTime.now
    assert_equal Money.new(0), statement.starting_amount
  end

  test "calculates starting amount for debit" do
    FactoryBot.create :transaction, account: account, amount: Money.new(10), credit_or_debit: Transaction::CREDIT, booked_at: 4.days.ago
    FactoryBot.create :transaction, account: account, amount: Money.new(1), credit_or_debit: Transaction::DEBIT, booked_at: 2.days.ago
    statement = Statement.create account: account, starting_at: 3.days.ago, ending_at: DateTime.now
    assert_equal Money.new(10), statement.starting_amount
  end

  test "inserting transaction updates statement" do
    tx1 = FactoryBot.create :transaction, account: account, amount: Money.new(1), credit_or_debit: Transaction::CREDIT, booked_at: 2.days.ago
    statement = Statement.create account: account, starting_at: 3.days.ago, ending_at: DateTime.now
    assert_includes statement.transactions, tx1
    assert_equal Money.new(1), statement.ending_amount
    tx2 = FactoryBot.create :transaction, account: account, amount: Money.new(1), credit_or_debit: Transaction::CREDIT, booked_at: 1.days.ago
    statement.reload
    assert_includes statement.transactions, tx2
    assert_equal Money.new(2), statement.ending_amount
  end
end
