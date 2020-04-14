module Private
  class TransfersController < ActionController::API
    rescue_from ActionController::ParameterMissing, with: :malformed_request

    def create
      transfer = Transfer.create(transfer_params)
      if transfer.errors.empty?
        head :no_content
      else
        render status: 400, json: {errors: [{
            code: 400,
            status: Rack::Utils::HTTP_STATUS_CODES[400],
            title: 'error executing transfer',
            detail: transfer.errors.full_messages.to_sentence
        }]}
      end
    end

    private

    def transfer_params
      params.require(:data).require(:attributes).permit(:amount, :from_account_id, :to_account_id)
    end

    def malformed_request(ex)
      render status: 400, json: {errors: [{
          code: 400,
          status: Rack::Utils::HTTP_STATUS_CODES[400],
          title: ex.message
       }]}
    end
  end
end
