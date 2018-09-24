class StatementDownloadController < ApplicationController
  include ActionController::MimeResponds

  def show
    statement = Statement.for_user(current_user!).for_account(params[:account_id]).find(params[:statement_id])
    respond_to do |format|
      format.csv do
        send_data statement.to_csv,
                  type: :csv,
                  filename: "Statement-#{statement.account_id}-#{statement.created_at.localtime.strftime('%Y%m%d')}.csv"
      end
      format.any do
        head(:unsupported_media_type)
      end
    end
  end
end
