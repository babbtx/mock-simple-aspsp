FactoryBot.define do
  factory :transaction do
    account
    amount { Money.new(rand(1000 * 100), account.currency) }
    booked_at { DateTime.now }
    credit_or_debit { [Transaction::CREDIT, Transaction::DEBIT].shuffle.first }
  end
end