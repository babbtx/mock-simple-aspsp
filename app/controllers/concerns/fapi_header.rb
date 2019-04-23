module FapiHeader
  extend ActiveSupport::Concern

  included do
    before_action :echo_fapi_header
  end

  def echo_fapi_header
    response.headers['x-fapi-interaction-id'] = request.headers['x-fapi-interaction-id'] if request.headers['x-fapi-interaction-id'].present?
  end
end