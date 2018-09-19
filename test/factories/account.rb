FactoryBot.define do
  factory :account do
    association :owner, factory: :user
    currency { 'GBP' }
    account_type { 'Personal' }
    account_subtype { 'CurrentAccount' }
    scheme_name { 'SortCodeAccountNumber' }
    identification { '%014d' % [rand(99999999999999)] }
  end
end
