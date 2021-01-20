require 'test_helper'

class GeneratorTest < ActiveSupport::TestCase
  test "generator shouldn't let balances go negative" do
    5.times do
      user = FactoryBot.create :user
      AccountsGenerator.generate_accounts_for_user(user)
      user.accounts.each do |account|
        account.transactions.each do |transaction|
          assert transaction.balance >= 0
        end
      end
    end
  end
end