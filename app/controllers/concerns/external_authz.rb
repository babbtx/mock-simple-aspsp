module ExternalAuthz
  extend ActiveSupport::Concern
  include CurrentUser

  CORRELATION_HEADERS = %w[
    Correlation-Id
    X-Request-Id
    Postman-Token
  ].collect(&:downcase)

  # an error if there's a failure with the external authorization service
  class ExternalAuthorizationError < StandardError
  end

  # an error if the external authorization service denies the client's request
  class ExternalAuthorizationDenied < StandardError
    attr_reader :response_json
    def initialize(message, response_json)
      super(message)
      @response_json = response_json
    end
  end

  included do
    rescue_from ExternalAuthorizationError, with: :render_authz_server_error
    rescue_from ExternalAuthorizationDenied, with: :render_authz_denied
  end

  class << self
    def configured?
      PingOneClient.configured? && ENV['PINGONE_AUTHZ_DECISION_URL']
    end
  end

  protected

  def decision_service
    @@authz_client ||= PingOneClient.new(url: ENV['PINGONE_AUTHZ_DECISION_URL']) do |faraday|
      faraday.request :json
    end
  end

  def authz_environment_id
    %r{environments/(?<environment>[^/]+)} =~ ENV['PINGONE_AUTHZ_DECISION_URL']
    environment
  end

  def authz_user_id
    current_user!.uuid
  end

  def external_authorize!(params = {})
    request_body = {
      parameters: params.merge(application: 'TreeQuote', controller: controller_name, action: action_name),
      userContext: {
        environment: { id: authz_environment_id },
        user: { id: authz_user_id }
      }
    }
    correlation_headers = request.headers.select{|h| CORRELATION_HEADERS.include?(h) }
    authz_response = decision_service.post(nil, request_body, correlation_headers)

    if authz_response.status != 200
      correlation_headers = authz_response.headers.select{|h| CORRELATION_HEADERS.include?(h) }
      logger.warn "External authz error code #{authz_response.status} request correlation ids #{correlation_headers.inspect}"
      logger.debug "External authz response headers = #{authz_response.headers.inspect}"
      logger.debug "External authz response body:\n-----------\n#{authz_response.body}\n-----------"
      raise ExternalAuthorizationError.new
    end

    if authz_response.body['decision'] != 'PERMIT'
      correlation_headers = authz_response.headers.select{|h| CORRELATION_HEADERS.include?(h) }
      logger.warn "External authz #{authz_response.body['decision']} request id #{authz_response.body['id']} correlation ids #{correlation_headers.inspect}"
      logger.debug "External authz response body:\n-----------\n#{authz_response.body}\n-----------"
      raise ExternalAuthorizationDenied.new(authz_response.body['decision'], authz_response.body)
    end

    authz_response.body
  end

  def render_authz_server_error
    head 500
  end

  def render_authz_denied
    head :forbidden
  end
end
