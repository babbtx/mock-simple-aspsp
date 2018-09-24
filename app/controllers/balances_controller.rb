class BalancesController < ApplicationController
  def index
    # this is the ugly way to do this:
    # get all of the accounts for the user,
    # then we'll get the most recent transaction and balance per
    accounts = Account.for_user(current_user!)

    # same intentional bug as described in TransactionsController#index
    # accounts = accounts.where(id: params[:account_id]) if params[:account_id].present?
    accounts = Account.where(id: params[:account_id]) if params[:account_id].present?

    transactions = accounts.collect(&:id).collect do |account|
      Transaction.for_account(account).newest_first.first
    end

    self_url = params[:account_id].present? ? account_balances_url(params[:account_id]) : balances_url
    render json: BalanceSerializer.new(transactions, links: {Self: self_url}, meta: { TotalPages: 1 }).serializable_hash
  end
end
