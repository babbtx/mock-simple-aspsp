module JwtSecured
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request!
    rescue_from JWT::VerificationError, JWT::DecodeError, with: :render_jwt_unauthorized
  end

  private

  # raises JWT::VerificationError if an Authorization header JWT is not present or not valid
  # by default, that exception renders :unauthorized
  # sets @auth_payload with the decoded JWT or the mock token
  def authenticate_request!
    @auth_payload ||= begin
      val = nil
      if mock_token.present?
        begin
          val = JSON.parse(mock_token).with_indifferent_access
        rescue JSON::JSONError
          raise JWT::DecodeError
        end
      else
        payload, header = JWT.decode(bearer_value, nil, false)
        @auth_header = header.with_indifferent_access
        val = payload.with_indifferent_access
      end
      logger.info "Bearer = #{val}"
      val
    end
  end

  def bearer_value
    if request.headers['Authorization'].present?
      request.headers['Authorization'].split(/\s+/).drop(1).join(' ')
    end
  end

  def mock_token
    bearer_value if (bearer_value.presence || '').starts_with?('{')
  end

  def render_jwt_unauthorized
    logger.warn "JWT unauthorized. Bearer = #{bearer_value}"
    head :unauthorized
  end

end
