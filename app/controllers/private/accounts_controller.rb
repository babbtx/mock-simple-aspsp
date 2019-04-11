module Private
  class AccountsController < ActionController::API
    def show
      account = Account.find(params[:id])
      render json: PrivateAccountSerializer.new(account).serializable_hash
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
