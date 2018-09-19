class TransactionsController < ApplicationController

  def index
    transactions = Transaction.for_user(current_user!)
    render json: TransactionSerializer.new(transactions, links: {Self: transactions_url}, meta: {TotalPages: 1}).serializable_hash
  end
end
