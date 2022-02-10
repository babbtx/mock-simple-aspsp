# this module extracts the PingOne Authorize configuration from a request header
module ExternalAuthzRequestConfig
  extend ActiveSupport::Concern

  def external_authz_configured?
    config = ping_one_client_options
    [ :url, :token_url, :client_id, :client_secret ].all? do |opt|
      config[opt].present?
    end
  end

  def ping_one_client_options
    JSON.parse(request.headers['X-PingOneAuthz-Config'] || '{}', symbolize_names: true)
  rescue JSONError
    logger.warn "External authz disabled after error parsing X-PingOneAuthz-Config value: #{request.headers['X-PingOneAuthz-Config']}"
    {}
  end

  def decision_url
    ping_one_client_options[:url]
  end
end