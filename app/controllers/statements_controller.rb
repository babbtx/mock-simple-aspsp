class StatementsController < ApplicationController
  before_action :load_statement, only: :show

  def index
    # start with all statements for the user
    statements = Statement.for_user(current_user!)

    # narrow down to the ones for the named account, if any
    # same intentional bug as described in TransactionsController#index
    # statements = statements.for_account(params[:account_id]) if params[:account_id].present?
    statements = Statement.for_account(params[:account_id]) if params[:account_id].present?

    statements = statements.oldest_first
    self_url = params[:account_id].present? ? account_statements_url(params[:account_id]) : statements_url
    render json: StatementSerializer.new(statements,
                                         links: {Self: self_url},
                                         meta: { TotalPages: 1 }).serializable_hash
  end

  def show
    render json: StatementSerializer.new(@statement,
                                         links: {Self: account_statement_url(@statement.account_id, @statement.id)},
                                         meta: { TotalPages: 1 }).serializable_hash
  end

  private

  def load_statement
    # Below is the "right" way to load a specifically named resource for an authenticated user:
    # @statement = Statement.for_user(current_user!).for_account(params[:account_id]).find(params[:id])

    # Above we search for statement by its identifier but only among the statements for this user and this account.
    # Even if that statement exists for another user or account but is not among the statements for this user and
    # account, find() will raise a RecordNotFound-type of error and in some superclass that gets mapped to 404.
    # Therefore the API never discloses that a resource really exists if despite the user not being authorized to see it.

    # Here is the wrong way to do it:
    # First find the resource, which returns 404 if it doesn't exist.
    @statement = Statement.find(params[:id])
    # Next check that the user is authorized to see it, and return 403.
    head(:forbidden) if @statement.account.owner != current_user!
  end
end
