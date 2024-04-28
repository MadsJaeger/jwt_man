# frozen_string_literal: true

module JwtMan
  ##
  # Payload for JWT token generation
  class Payload < Hash
    RESERVED_KEYS = %i[iss aud sub jti oat iat exp user].freeze
    attr_reader :user

    ##
    # user should be a user object. oat is the original authentication time. If not given, it will be set to iat, i.e.
    # a `session`.
    def initialize(user:, **kwargs)
      super
      self.user = user

      kwargs.each do |k, v|
        if respond_to?("#{k}=")
          send("#{k}=", v)
        else
          self[k] = v
        end
      end

      %i[oat iat exp].each do |key|
        send("#{key}=", send(key)) unless kwargs.key?(key)
      end
      merge!({ iss: iss, aud: aud, sub: sub, jti: jti }.compact)
    end

    ##
    # Originated at is the original authentication time.
    def oat
      @oat ||= iat
    end

    ##
    # Issued at is the time the token was issued. Defaults to now.
    def iat
      @iat ||= Time.zone.now.floor
    end

    ##
    # Expiration time is the time the token expires. Defaults to now + config.duration.
    def exp
      @exp ||= iat + Config.duration
    end

    ##
    # Each timed variable is expected to be set as a time and held as such but kept as an integer in the payload.
    # Notice that times are floored to the second.
    %i[oat iat exp].each do |key|
      define_method("#{key}=") do |value|
        instance_variable_set("@#{key}", value)
        self[key] = value&.to_i
      end
    end

    ##
    # The issuer is the application name.
    def iss
      Config.issuer
    end

    ##
    # The audience is the application name.
    def aud
      Config.audience
    end

    ##
    # The subject is the application name.
    def sub
      Config.subject
    end

    ##
    # The user object is stored as a JSON object in the payload.
    def user=(user)
      @user = user
      self[:user] = if user.is_a? Hash
                      user
                    else
                      Config.user_to_json_proc.call(@user)
                    end
    end

    # The jti is a unique identifier for the token. It is used to blacklist the token.
    def jti
      @jti ||= Jti.new(user_id || Random.hex(Config.jti_hex_length))
    end
    attr_writer :jti

    private

    def user_id
      user.is_a?(Hash) ? user['id'] : user.id
    end
  end
end
