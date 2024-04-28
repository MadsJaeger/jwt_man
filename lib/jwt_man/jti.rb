# frozen_string_literal: true

module JwtMan
  ##
  # JTI generator. Generating a plausible unique string: MD5 hash of a random hex string, user id, user object id, and
  # iat (issued at) timestamp. Duplication is ngelible.
  class Jti < String
    def initialize(user_id)
      @user_id = user_id
      super construct
    end

    private

    def construct
      Digest::MD5.hexdigest [
        Random.hex(Config.jti_hex_length),
        @user_id.to_s,
        Time.zone.now.strftime('%Y%m%d%H%M%S%L%N')
      ].join
    end
  end
end
