module PingAuthorizeClient
  class << self

    def configured?
      %w[ PING_AUTHZ_SHARED_SECRET ].all? do |var|
        ENV[var].present?
      end
    end

    def new(options, &block)
      Faraday.new(options) do |f|
        f.headers['PDG-TOKEN'] = ENV['PING_AUTHZ_SHARED_SECRET']
        f.ssl.verify = false
        f.response :json
        f.response :logger, Rails.logger, {headers: true, bodies: true} if debug?
        yield(f) if block_given?
        f.adapter Faraday.default_adapter
      end
    end

    def debug?
      %w[ true on yes 1 ].include?(ENV['PING_DEBUG'])
    end

  end # class << self
end
