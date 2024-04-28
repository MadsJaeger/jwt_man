# frozen_string_literal: true

module JwtMan
  ##
  # Random token generation and storage for refresh tokens. Associated to a user and a JTI. The JTI is a unique
  # identifier for the JWT and it is issued in pair with the refresh token. Only one refresh token is allowed per JTI.
  # We pait them up so when decoding a jwt we can find the issued refresh token and verify it against the recieved.
  # The orignal issued refresh token is encryted and the encrypted token is stored in the database, and cant be
  # decrypted.
  class RefreshToken < JtiList
    class << self
      def key
        'rti'
      end

      def find_by(user_id: nil, jti: nil, token: nil)
        rt = super(user_id: user_id, jti: jti) || return

        unless token
          rt.token = 'UNKNOWN'
          return rt
        end

        return nil unless rt.encrypted_token == Digest::SHA256.hexdigest(token)

        rt.token = token
        rt
      end

      def where(user_id: nil, jti: nil)
        super(user_id: user_id, jti: jti).each do |refresh_token|
          refresh_token.token = 'UNKNOWN'
        end
      end
    end

    ##
    # What is sent to the client.
    attr_accessor :token

    def initialize(user_id:, jti:, token: nil, exp: nil)
      super(user_id: user_id, jti: jti, exp: exp)
      self.token = token || SecureRandom.uuid
    end

    ##
    # The encrypted token is stored in the database. It is encrypted with SHA256 and can not be decrypted. However, we
    # can compare it to an encrypted token and see if they match.
    def encrypted_token
      if saved?
        redis.get(key)
      else
        Digest::SHA256.hexdigest(token)
      end
    end

    alias destroy_now destroy

    def destroy
      if Config.grace_period
        expire(Config.grace_period)
      else
        super
      end
    end
    alias destroy! destroy

    private

    def duration
      Config.refresh_token_duration
    end

    def data
      encrypted_token
    end
  end
end

# :rotate!
