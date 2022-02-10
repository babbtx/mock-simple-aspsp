$decision_service_clients = Concurrent::Map.new

module ExternalAuthz
  extend ActiveSupport::Concern
  include CurrentUser
  include ExternalAuthzRequestConfig

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

  protected

  def decision_service
    config = ping_one_client_options
    key = config.sort.to_h
    $decision_service_clients.compute_if_absent(key) do
      PingOneClient.new(config)
    end
  end

  def authz_environment_id
    # this extracts the environment id from the decision URL
    %r{environments/(?<environment>[^/]+)} =~ decision_url
    environment
  end

  def authz_user_id
    current_user!.uuid
  end

  def default_params
    application_name = ENV['APPLICATION_NAME'] || 'TreeQuote'
    {
      Application: application_name,
      "#{application_name}.Controller": controller_name,
      "#{application_name}.Action": action_name
    }
  end

  def external_authorize!(params = {})
    request_body = {
      parameters: params.merge(default_params),
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

  # This authorizes an entire collection by (1) passing the array of ids to the server
  # then (2) allowing/keeping the collection objects whose ids match any returned include-id
  # then (3) denying/filtering the collection objects whose ids match any returned by exclude-id.
  # The collection is modified in place.
  # The ids are passed to the server like {"accounts": "[\"1\", \"2\"]"} -- note the JSON-formatted array.
  # Same as #external_authorize!, this returns the authorization result.
  def external_authorize_collection!(array, params = {}, typename: array.first.class.name.underscore)
    if (array||[]).size == 0
      external_authorize!(params)
    else
      get_id = -> (obj){ obj.respond_to?(:id) ? obj.id : obj.try(:[], :id) || obj.try(:[], 'id') }
      authz_result = external_authorize!(params.merge(typename => array.collect(&get_id).to_json))
      includes = (authz_result['statements']||[])
                   .collect{|s| s['payload'] if s['code'] == 'include-id'}
                   .compact
      array.select!{ |obj| includes.collect(&:to_s).include?(get_id.call(obj).to_s) } unless includes.empty?
      excludes = (authz_result['statements']||[])
                   .collect{|s| s['payload'] if s['code'] == 'exclude-id'}
                   .compact
      array.reject!{ |obj| excludes.collect(&:to_s).include?(get_id.call(obj).to_s) } unless excludes.empty?
      authz_result
    end
  end

  def render_authz_server_error
    head 500
  end

  def render_authz_denied(ex)
    reason = (ex.response_json['statements']||[])
               .collect{|s| s['payload'] if s['code'] == 'denied-reason'}
               .first
    reason ||= 'Denied by authorization policy'
    render status: 403, json: {errors: [{
      code: 403,
      status: Rack::Utils::HTTP_STATUS_CODES[403],
      detail: reason
    }]}
  end
end
