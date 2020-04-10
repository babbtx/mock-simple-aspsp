module SignIn
  extend ActiveSupport::Concern

  def sign_in(user)
    @current_user = user
    @authz_header  = nil
  end

  # if signed in (see #sign_in), returns a hash with an Authorization header
  def authz_headers
    @authz_header ||= begin
      if @current_user
        payload = {sub: @current_user.uuid}
        {'Authorization': "Bearer #{JWT.encode(payload, 'password')}"}
      else
        {}
      end
    end
  end
end

ActionDispatch::IntegrationTest.send(:include, SignIn)