module Private
  class PermissionsController < ApiController
    def show
      data = {
        accounts: true,
        transactions: true,
        transfers: true,
        offers: true
      }
      render json: data
    end
  end
end