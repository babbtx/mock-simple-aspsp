require 'test_helper'

class GeneratorTest < ActiveSupport::TestCase
  test "doesn't let balances go negative" do
    3.times do
      user = FactoryBot.create :user
      AccountsGenerator.generate_accounts_for_user(user)
      user.accounts.each do |account|
        account.transactions.each do |transaction|
          assert transaction.balance >= 0
        end
      end
    end
  end

  test "sets balances properly" do
    3.times do
      user = FactoryBot.create :user
      AccountsGenerator.generate_accounts_for_user(user)
      user.accounts.each do |account|
        balance = 0
        account.transactions.order(booked_at: :asc).each do |transaction|
          balance += transaction.debit? ? transaction.amount * -1 : transaction.amount
          assert_equal transaction.balance, balance
        end
      end
    end
  end

  test "minimize sql statements" do
    user = FactoryBot.create :user
    statements = []
    callback = ->(*, payload) { statements << payload[:sql] }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      AccountsGenerator.generate_accounts_for_user(user)
    end
    # begin
    # insert into accounts x 3
    # commit
    # select accounts
    # (subtotal = 6)
    # PER ACCOUNT
    # begin
    # insert into transaction x 100
    # commit
    # (transactions subtotal 102 x 3 = 306)
    # select transactions
    # begin
    # PER STATEMENT (there are 4)
    # select transactions
    # insert into statements
    # commit
    # (statements subtotal 11 x 3 = 33)
    # grand total = 345
    assert_equal 345, statements.size, %{statements = \n#{statements.collect{|s|s[0,40]}.join("\n")}}
  end
end