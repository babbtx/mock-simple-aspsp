class AccountsController < ApplicationController

  append_before_action :create_user_and_accounts

  def index
    accounts = Account.for_user(current_user!)
    render json: AccountSerializer.new(accounts, links: {Self: accounts_url}, meta: {TotalPages: 1}).serializable_hash
  end

  def show
    account = Account.for_user(current_user!).find(params[:id])
    render json: AccountSerializer.new(account, links: {Self: account_url(account.id)}).serializable_hash
  end

  private

  # if we don't have the user yet
  # just generate a user and some accounts
  def create_user_and_accounts
    unless current_user
      @current_user = User.create(uuid: @auth_payload[:sub])
      AccountsGenerator.generate_accounts_for_user(@current_user)
    end
  end
end
