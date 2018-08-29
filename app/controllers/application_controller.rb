class ApplicationController < ActionController::API
  include JwtSecured
  include CurrentUser
end
