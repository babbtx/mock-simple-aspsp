module AccountsGenerator
  class << self
    def generate_accounts_for_user(user)
      3.times do
        Account.create! owner: user,
                        currency: 'GBP',
                        account_type: 'Personal',
                        account_subtype: %w{ChargeCard CreditCard CurrentAccount EMoney Savings}.shuffle.first,
                        scheme_name: 'SortCodeAccountNumber',
                        identification: '%014d' % [rand(99999999999999)]
      end
    end
  end
end