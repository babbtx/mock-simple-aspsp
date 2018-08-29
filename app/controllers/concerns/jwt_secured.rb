module JwtSecured
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request!
    rescue_from JWT::VerificationError, JWT::DecodeError, with: :render_jwt_unauthorized
  end

  private

  def authenticate_request!
    @auth_payload ||= begin
      payload, header = JWT.decode(bearer_value, nil, false)
      @auth_header = header.with_indifferent_access
      payload.with_indifferent_access
    end
  end

  def bearer_value
    if request.headers['Authorization'].present?
      request.headers['Authorization'].split(' ').last
    end
  end

  def render_jwt_unauthorized
    logger.warn "JWT unauthorized. Bearer = #{bearer_value}"
    head :unauthorized
  end
end