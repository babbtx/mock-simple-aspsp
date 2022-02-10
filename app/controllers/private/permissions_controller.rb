module Private
  class PermissionsController < ApiController
    include ExternalAuthz

    append_before_action :create_user

    def show
      data = get_permissions
      render json: data
    end

    private

    def get_permissions
      if external_authz_configured?
        authz_result = external_authorize!
        permissions = (authz_result['statements']||[])
          .select {|statement| statement['code'] == 'set-permission' }
          .collect {|statement| [statement['payload'], true]}
          .to_h
        permissions.merge(accounts: true) # the frontend doesn't work right now without accounts
      else
        # default permissions
        {
          accounts: true,
          transactions: true,
          transfers: true,
          offers: true
        }
      end
    end

    def create_user
      User.create(uuid: @auth_payload[:sub]) unless current_user
    end
  end
end
