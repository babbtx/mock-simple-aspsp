class AccountsController < ApplicationController

  def index
    accounts = Account.for_user(current_user)
    render json: AccountSerializer.new(accounts, links: {Self: accounts_url}, meta: {TotalPages: 1}).serializable_hash
  end

  def show
    account = Account.for_user(current_user).find(params[:id])
    render json: AccountSerializer.new(account, links: {Self: account_url(account.id)}).serializable_hash
  end
end
