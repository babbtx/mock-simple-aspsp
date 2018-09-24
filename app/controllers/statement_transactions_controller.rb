class StatementTransactionsController < ApplicationController
  def index
    statement = Statement.for_user(current_user!).for_account(params[:account_id]).find(params[:statement_id])
    transactions = statement.transactions.oldest_first
    self_url = account_statement_transactions_url(statement.account_id, statement.id)
    render json: TransactionSerializer.new(transactions,
                                           links: {Self: self_url},
                                           meta: {
                                               TotalPages: 1,
                                               FirstAvailableDateTime: transactions.first.booked_at.localtime.iso8601,
                                               LastAvailableDateTime: transactions.last.booked_at.localtime.iso8601
                                           }).serializable_hash
  end
end
