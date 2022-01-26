class AccountsController < ApplicationController
  include ExternalAuthz

  append_before_action :create_user_and_accounts

  def index
    accounts = Account.for_user(current_user!).to_a
    external_authorize_collection!(accounts) if ExternalAuthz.configured?
    render json: AccountSerializer.new(accounts, links: {Self: accounts_url}, meta: {TotalPages: 1}).serializable_hash
  end

  def show
    #account = Account.for_user(current_user!).find(params[:id])
    account = Account.find(params[:id])
    external_authorize!(account: params[:id]) if ExternalAuthz.configured?
    render json: AccountSerializer.new(account, links: {Self: account_url(account.id)}).serializable_hash
  end

  private

  # if we don't have the user yet
  # just generate a user and some accounts
  def create_user_and_accounts
    User.create(uuid: @auth_payload[:sub]) unless current_user
    AccountsGenerator.generate_accounts_for_user(current_user) if Account.for_user(current_user).empty?
  end
end
