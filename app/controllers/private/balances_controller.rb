module Private
  class BalancesController < ApiController

    # Lookup the balances for any user.
    # The user can be in a path param or in the token.
    def index
      # Same as OpenBanking balances controller -
      # get all of the accounts for the user,
      # then we'll get the most recent transaction and balance per account.
      accounts = Account.for_user(find_user_by_param_or_token)

      transactions = accounts.collect(&:id).collect do |account|
        Transaction.for_account(account).newest_first.first
      end.compact

      render json: PrivateBalanceSerializer.new(transactions).serializable_hash
    end

  end
end
