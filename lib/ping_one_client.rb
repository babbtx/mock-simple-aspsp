require 'oauth2'

module PingOneClient
  class << self

    ATTRS = [:client_id, :client_secret, :token_url].freeze

    attr_accessor *ATTRS

    def new(options, &block)
      options = extract_and_assign_attrs(options)
      create_http_client(options, &block)
    end

    def debug?
      %w[ true on yes 1 ].include?(ENV['PINGONE_DEBUG'])
    end

    private

    def extract_and_assign_attrs(options)
      attrs = options.dup
      options = attrs.slice!(*ATTRS)
      attrs.each {|a,v| self.public_send("#{a}=", v)}
      options
    end

    def create_http_client(options, &block)
      Faraday.new(options) do |f|
        f.request :authorization, 'Bearer', -> { access_token.token }
        f.request :json
        f.response :json
        f.response :logger, Rails.logger, {headers: true, bodies: true} if debug?
        yield(f) if block_given?
        f.adapter Faraday.default_adapter
      end
    end

    def access_token
      unless @access_token && !@access_token.expired?
        client = OAuth2::Client.new(client_id, client_secret,
                                    token_url: token_url,
                                    token_method: :post,
                                    auth_scheme: :basic_auth,
                                    logger: Rails.logger)
        @access_token = client.client_credentials.get_token
      end
      @access_token
    end

  end # class << self
end
