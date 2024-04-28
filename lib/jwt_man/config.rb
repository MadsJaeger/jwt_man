# frozen_string_literal: true

module JwtMan
  ##
  # Configuration for JwtMan, storage of changable attributes. Should not be changed during lifespan of application.
  class Config
    ATTRS = %i[
      duration secret algorithm issuer verify_iss audience verify_aud subject verify_sub verify_jti
      jti_hex_length refresh_token_duration exp_leeway user_to_json_proc user_from_json_proc
      redis grace_period user_refresh_always
    ].freeze

    class << self
      def configure
        yield self
        Decode.reset_options
      end

      attr_writer(*ATTRS)

      ##
      # Redis instance to be used for JwtMan. This will store, whitelist, blacklist, refrsh_tokens and user_refresh_list
      # entries.
      def redis
        @redis ||= Redis.new
      end

      ##
      # Default duration of a JWT token
      # Consider using relatively short lived tokens, and refresh tokens to extend the lifetime of a token. This reduces
      # the responsibility of the blacklist system.
      def duration
        @duration ||= 15.minutes
      end

      ##
      # Secret used to sign JWT tokens. HMAC secret for HS***, RSA private key for RS***
      def secret
        @secret || raise(ArgumentError, 'JwtMan: secret must be set')
      end

      ##
      # Algorithm used to sign JWT tokens
      def algorithm
        @algorithm ||= 'HS256'
      end

      ##
      # Leeway for expiration verification. This is to account for clock skew between servers.
      def exp_leeway
        @exp_leeway ||= 0
      end

      ##
      # Issuer of JWT tokens
      attr_reader :issuer

      ##
      # If variable set issuer verification will take place. veriy_issuer may be a string, StringOrUri, a regex, or a
      # proc. StirngOrUri: 'Company Name or https://company.com'.
      attr_reader :verify_iss

      ##
      # Audience of JWT tokens
      attr_reader :audience

      ##
      # If variable set audience verification will take place. veriy_aud may be a string, StringOrUri.
      attr_reader :verify_aud

      ##
      # Subject of JWT tokens
      attr_reader :subject

      ##
      # If variable set subject verification will take place. veriy_sub may be a string, StringOrUri.
      attr_reader :verify_sub

      ##
      # Set to true if Blacklist should be used to verify JTI.
      attr_reader :verify_jti

      ##
      # Hex length of the JTI
      def jti_hex_length
        @jti_hex_length ||= 6
      end

      ##
      # Duration of a refresh token
      def refresh_token_duration
        @refresh_token_duration ||= 3.months
      end

      ##
      # Debounce time for revokation of refresh tokens. This can account for clock skwe between servers. Also, this
      # allows for a grace period for the refresh token to be reused before completly revoked.
      def grace_period
        @grace_period ||= 8.seconds
      end

      ##
      # Proc to serialize user object to JSON. This is used to store the user object in the JWT payload.
      def user_to_json_proc
        @user_to_json_proc ||= proc { |user| user.as_json }
      end

      ##
      # Proc to instnatiate user object from JSON. Used upon refresh of token.
      def user_from_json_proc
        @user_from_json_proc ||= proc { |hash| User.new(**hash) }
      end

      def user_refresh_proc
        @user_refresh_proc ||= proc do |json|
          User.find(json['id'])
        rescue ActiveRecord::RecordNotFound
          raise JWT::UserNotFound, 'User not found'
        end
      end

      ##
      # Should the user object be refreshed on every request.
      def user_refresh_always
        @user_refresh_always ||= false
      end
    end
  end
end
