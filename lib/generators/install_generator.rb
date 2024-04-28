# frozen_string_literal: true

require 'rails/generators'

module JwtMan
  module Generators
    ##
    # Adds role migration to client project
    class InstallGenerator < Rails::Generators::Base
      desc 'Add JwtMan configuration to client project'
      source_root File.expand_path('templates', __dir__)
      def install
        template 'jwt_man_config.rb', Rails.root.join('config/initializers/jwt_man_config.rb')
      end
    end
  end
end
