# frozen_string_literal: true

module JwtMan
  ##
  # Decode a JWT token and refresh if expired.
  # The JWT is decoded. If the JWT is expired, the refresh token is destroyed and a JWT token pair is encoded. If not
  # expired refresh may takepalce is the user is marked for refresh. The user is marked for refresh the JWT and token
  # may be replayed.
  class Decode
    class << self
      ##
      # Options for JWT.decode. Cached as it is generated from config.
      def options
        @options ||= {
          algorithm: algorithm,
          required_claims: required_claims,
          verifiy_expiration: true,
          exp_leeway: exp_leeway&.to_i,
          verify_iat: true,
          verify_jti: verify_jti_proc,
          verify_iss: verify_iss ? true : nil,
          iss: verify_iss,
          verify_aud: verify_aud ? true : nil,
          aud: verify_aud,
          verify_sub: verify_sub ? true : nil,
          sub: verify_sub
        }.compact
      end

      def reset_options
        @options = nil
      end

      private

      delegate :algorithm, :verify_iss, :verify_aud, :verify_sub, :verify_jti, :exp_leeway, to: Config

      def required_claims
        claims = %i[exp iat jti user oat]
        claims << :iss if verify_iss
        claims << :aud if verify_aud
        claims << :sub if verify_sub
        claims.map(&:to_s)
      end

      def verify_jti_proc
        return nil unless verify_jti

        Proc.new do |jti, payload|
          Blacklist.find_by(jti: jti, user_id: payload['user']['id']).nil?
        end
      end
    end

    def initialize(jwt:, token:)
      @jwt   = jwt
      @token = token
      decode
    end

    attr_reader :header

    ##
    # Will raise JWT::DecodeError or any of its subclasses if we do not trust the received JWT. If the JWT is valid,
    # and not expired it will return the original payload and header. If the JWT is expired, it will return the ...
    def decode(**kwargs)
      self.payload, self.header = JWT.decode(
        @jwt,
        Config.secret,
        true,
        self.class.options.merge(kwargs)
      )
      refresh! if refreshor.refresh?
      [@payload, @header]
    rescue JWT::ExpiredSignature
      self.payload, self.header = decode(verify_expiration: false)
      refresh_token.destroy!
      refresh!
      [@payload, @header]
    end

    def refresh_token
      @refresh_token ||= RefreshToken.find_by(user_id: @payload[:user]['id'], jti: jti, token: @token.to_s)\
                     || raise(JWT::RefreshTokenNotFound, 'Refresh token not found')
    end
    alias verify_refresh_token! refresh_token

    def refresh!
      return self if @refreshed

      refresh_token.destroy!
      refreshor.refresh!
      @refreshed = true

      self
    end
    alias refresh refresh!

    def refreshed?
      @refreshed || false
    end

    %i[jwt token payload].each do |method|
      eval <<-RUBY, binding, __FILE__, __LINE__ + 1
        def #{method}
          @refreshor.#{method} || @#{method}
        end
      RUBY
    end

    delegate :jti, to: :payload
    delegate :user, to: :refreshor

    private

    def refreshor
      @refreshor ||= Refreshor.new(@payload)
    end

    def payload=(hash)
      @payload = Payload.new(**hash.symbolize_keys)
    end

    def header=(hash)
      @header = hash.symbolize_keys
    end
  end
end
