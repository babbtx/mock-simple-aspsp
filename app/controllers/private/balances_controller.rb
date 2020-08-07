module Private
  class BalancesController < ActionController::API
    def index
      # same as OpenBanking balances controller
      # get all of the accounts for the user,
      # then we'll get the most recent transaction and balance per
      # the user is from param rather than from token
      # this is obviously not secure
      accounts = Account.for_user(find_user)

      transactions = accounts.collect(&:id).collect do |account|
        Transaction.for_account(account).newest_first.first
      end.compact

      render json: PrivateBalanceSerializer.new(transactions).serializable_hash

    end

    private


    def find_user
      user = User.find_by(uuid: params[:user_id])
      unless user
        # generate data if we don't have one
        user = User.create(uuid: params[:user_id])
        AccountsGenerator.generate_accounts_for_user(user)
      end
      user
    end
  end
end
