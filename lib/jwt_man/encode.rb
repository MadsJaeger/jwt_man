# frozen_string_literal: true

module JwtMan
  ##
  # Encode a JWT token, i.e. generate a JWT token for a user, place it in the whitelist if configred so, and generate a
  # refresh token.
  class Encode
    attr_accessor :user
    attr_reader :jwt

    ##
    # user should be a user object. oat is the original authentication time, is used to tell when the user has last
    # been refreshed, which may be the first issance in the serie. Give additional kwargs to enrich the payload.
    def initialize(user, **kwargs)
      self.user = user
      @kwargs   = kwargs
      encode
    end

    def encode
      @jwt = JWT.encode payload, Config.secret, Config.algorithm
    end

    def payload
      @payload ||= Payload.new(user: user, **@kwargs)
    end
    delegate :jti, to: :payload

    ##
    # The token which is used to refresh the JWT token. To be delivered to the client.
    def token
      @token ||= refresh_token.token
    end

    ##
    # The refresh token, digest of token. To be stored in the database.
    def refresh_token
      @refresh_token ||= RefreshToken.create!(
        user_id: user_id,
        jti: jti,
        exp: payload.iat + Config.refresh_token_duration
      )
    end

    private

    def user_id
      user.is_a?(Hash) ? user['id'] : user.id
    end
  end
end
