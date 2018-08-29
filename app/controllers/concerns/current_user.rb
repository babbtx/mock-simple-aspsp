module CurrentUser
  extend ActiveSupport::Concern
  include JwtSecured

  class UserNotFound < ActiveRecord::RecordNotFound
  end

  included do
    rescue_from UserNotFound, with: :render_user_unauthorized
  end
  private

  def current_user
    authenticate_request!
    @current_user ||= User.find_by(uuid: @auth_payload[:sub]) || maybe_raise_user_not_found
  end

  def maybe_raise_user_not_found
    raise UserNotFound.new("User not found")
  end

  def render_user_unauthorized
    logger.warn "User not found. Auth payload = #{@auth_payload}"
    head :unauthorized
  end
end