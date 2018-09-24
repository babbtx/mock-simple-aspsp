class StatementsController < ApplicationController
  def index
    # start with all statements for the user
    statements = Statement.for_user(current_user!)

    # narrow down to the ones for the named account, if any
    statements = statements.for_account(params[:account_id]) if params[:account_id].present?

    statements = statements.oldest_first
    self_url = params[:account_id].present? ? account_statements_url(params[:account_id]) : statements_url
    render json: StatementSerializer.new(statements, links: {Self: self_url}, meta: { TotalPages: 1 }).serializable_hash
  end
end
