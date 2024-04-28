# frozen_string_literal: true

require 'jwt'
require 'redis'

require 'jwt_man/version'
require 'jwt_man/config'
require 'jwt_man/collection_duck'
require 'jwt_man/jti'
require 'jwt_man/user_refresh_list'
require 'jwt_man/jti_list'
require 'jwt_man/blacklist'
require 'jwt_man/refresh_token'
require 'jwt_man/payload'
require 'jwt_man/encode'
require 'jwt_man/decode'
require 'jwt_man/user_observer'
require 'jwt_man/refreshor'

require 'generators/install_generator' if defined?(Rails)

module JWT
  ##
  # User could not be found in the database. The user has been deleted since the JWT was issued. We do not raise
  # ActiveRecord::RecordNotFound as this could lead to 404 instead of 401.
  class UserNotFound < DecodeError; end
  class RefreshTokenNotFound < DecodeError; end
end

# :nodoc:
module JwtMan
  class << self
    def config
      JwtMan::Config
    end

    delegate :configure, to: :config
  end
end
