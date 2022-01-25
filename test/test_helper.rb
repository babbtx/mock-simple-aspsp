ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'mocha/minitest'
require 'webmock/minitest'

require_relative 'support/sign_in'

class ActiveSupport::TestCase
  # Using factories not fixtures
  fixtures []
end
