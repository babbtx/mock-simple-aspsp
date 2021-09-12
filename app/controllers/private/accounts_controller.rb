module Private
  class AccountsController < ApiController
    # Lookup accounts for any user
    # The user can be in a path param or in the token.
    def index
      accounts = Account.for_user(find_user_by_param_or_token)
      render json: PrivateAccountSerializer.new(accounts).serializable_hash
    end

    # Get details of any account
    def show
      account = Account.find(params[:id])
      render json: PrivateAccountSerializer.new(account).serializable_hash
    end
  end
end
