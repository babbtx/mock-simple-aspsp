module ExternalAuthzEnvConfig
  extend ActiveSupport::Concern

  # doing this "the old way" in order to define this method on the including module,
  # not on the ultimate class in which the modules are included
  # e.g. ExternalAuthz.configured?
  def self.included(base)
    base.class_eval do
      def self.configured?
        %w[
          PINGONE_AUTHZ_DECISION_URL
          PINGONE_TOKEN_URL
          PINGONE_CLIENT_ID
          PINGONE_CLIENT_SECRET
        ].all? do |var|
          ENV[var].present?
        end
      end
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
    ENV['PINGONE_AUTHZ_DECISION_URL']
  end
end