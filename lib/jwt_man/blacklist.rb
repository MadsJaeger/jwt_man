# frozen_string_literal: true

module JwtMan
  ##
  # JTI tokens that are blacklisted. Blacklisting prevents the token from being used for authentication, when configured
  # with the verify_jti true.
  class Blacklist < JtiList
    class << self
      def key
        'bjti'
      end
    end
  end
end
