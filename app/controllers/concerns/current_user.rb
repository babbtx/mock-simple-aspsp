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
    @current_user ||= User.find_by(uuid: @auth_payload[:sub])
  end

  def current_user!
    raise UserNotFound.new("User not found") unless current_user
    @current_user
  end

  def render_user_unauthorized
    logger.warn "User not found. Auth payload = #{@auth_payload}"
    head :unauthorized
  end
end