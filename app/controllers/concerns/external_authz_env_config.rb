module ExternalAuthzEnvConfig
  extend ActiveSupport::Concern

  def self.ping_one_env_configured?
    %w[
      PINGONE_AUTHZ_DECISION_URL
      PINGONE_TOKEN_URL
      PINGONE_CLIENT_ID
      PINGONE_CLIENT_SECRET
    ].all? do |var|
      ENV[var].present?
    end
  end

  def external_authz_configured?
    unless Rails.env.test?
      @@external_authz_configured ||= ExternalAuthzEnvConfig.ping_one_env_configured?
    else
      ExternalAuthzEnvConfig.ping_one_env_configured?
    end
  end

  def ping_one_client_options
    {
      url: ENV['PINGONE_AUTHZ_DECISION_URL'],
      token_url: ENV['PINGONE_TOKEN_URL'],
      client_id: ENV['PINGONE_CLIENT_ID'],
      client_secret: ENV['PINGONE_CLIENT_SECRET']
    }
  end

  def decision_url
    ping_one_client_options[:url]
  end
end