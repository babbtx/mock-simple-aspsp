class ApplicationController < ActionController::API
  include JwtSecured
  include CurrentUser
  include FapiHeader
end
