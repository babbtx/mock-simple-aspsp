module Private
  class ApiController < ActionController::API
    include JwtSecured
    include CurrentUser

    private

    def find_user_by_param_or_token
      user_uuid = params[:user_id].presence || current_user!.uuid
      user = User.find_by(uuid: user_uuid)
      unless user
        # generate data if we don't have one
        user = User.create(uuid: user_uuid)
        AccountsGenerator.generate_accounts_for_user(user)
      end
      user
    end

  end
end