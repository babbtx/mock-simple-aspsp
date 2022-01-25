require 'oauth2'

module PingOneClient
  class << self

    def configured?
      %w[ PINGONE_TOKEN_URL PINGONE_CLIENT_ID PINGONE_CLIENT_SECRET ].all? do |var|
        ENV[var].present?
      end
    end

    def new(options, &block)
      Faraday.new(options) do |f|
        f.request :authorization, 'Bearer', access_token.token
        f.response :json
        f.response :logger, Rails.logger, {headers: true, bodies: true} if debug?
        yield(f) if block_given?
        f.adapter Faraday.default_adapter
      end
    end

    def debug?
      %w[ true on yes 1 ].include?(ENV['PINGONE_DEBUG'])
    end

    private

    def access_token
      unless @access_token && !@access_token.expired?
        client = OAuth2::Client.new(ENV['PINGONE_CLIENT_ID'], ENV['PINGONE_CLIENT_SECRET'],
                                    token_url: ENV['PINGONE_TOKEN_URL'],
                                    token_method: :post,
                                    auth_scheme: :basic_auth,
                                    logger: Rails.logger)
        @access_token = client.client_credentials.get_token
      end
      @access_token
    end

  end # class << self
end
