class TransactionsController < ApplicationController

  def index
    # start with the transactions owned by the user
    transactions = Transaction.for_user(current_user!)

    # For controllers that are used both as top-level resource controllers or sub-resource controllers
    # this next line is "the right way" to do this in RoR: further restrict the data scope of "transactions
    # owned by the user" to include only the records "under" the parent resource, in this case the account.
    #
    # transactions = transactions.for_account(params[:account_id]) if params[:account_id].present?
    transactions = Transaction.for_account(params[:account_id]) if params[:account_id].present?

    # However, the actual line of code is practically a typo away from the correct line of code.
    # The erroneous line of code grabs all transactions for the named account, regardless of
    # who owns the account.
    #
    # More comments:
    #
    # 1) The token is theoretically validated at this point. The caller in question is a authenticated.
    # An access control layer doesn't help prevent this data breach (not without looking at the URL component).
    # For a similar real world bug leading to breach see:
    # https://krebsonsecurity.com/2018/08/fiserv-flaw-exposed-customer-data-at-hundreds-of-banks/
    #
    # 2) A better RoR developer would use something like CanCanCan for resource-level authorization
    # within the code. It's sort of a way to do a double-check that the call below was done right.
    # However, IIRC, CanCanCan doesn't do well with collections like this.

    transactions = transactions.oldest_first
    self_url = params[:account_id].present? ? account_transactions_url(params[:account_id]) : transactions_url
    render json: TransactionSerializer.new(transactions,
                                           links: {Self: self_url},
                                           meta: {
                                               TotalPages: 1,
                                               FirstAvailableDateTime: transactions.first.booked_at.localtime.iso8601,
                                               LastAvailableDateTime: transactions.last.booked_at.localtime.iso8601
                                           }).serializable_hash
  end
end
