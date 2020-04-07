module Private
  class AccountsController < ActionController::API
    def show
      account = Account.find(params[:id])
      render json: PrivateAccountSerializer.new(account).serializable_hash
    end
  end
end
