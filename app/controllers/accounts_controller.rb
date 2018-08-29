class AccountsController < ApplicationController

  def show
    account = Account.find(params[:id])
    render json: AccountSerializer.new(account, links: {self: account_url(account.id)}).serializable_hash
  end
end
