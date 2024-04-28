# frozen_string_literal: true

JwtMan.configure do |config|
  # The Redis instance to use
  # config.redis = Redis.new

  # The secret to use to sign the token, will raise error if not set
  # config.secret = nil

  # The algorithm used to sign the token
  # config.algorithm = 'HS256'

  # The duration of the access token
  # config.duration = 15.minutes

  # The time leeway for token expiration
  # config.exp_leeway = 0

  # The duration of the refresh token
  # config.refresh_token_duration = 3.months

  # The grace period for refresh token expiration
  # config.grace_period = 8.seconds



  # The issuer of the token
  # config.issuer = nil

  # Verification of the issuer may be a string, StringOrUri, a regex, or a
  # proc. StirngOrUri: 'Company Name or https://company.com'.
  # config.verify_iss = nil

  # The audience of the token
  # config.audience = nil

  # Verification of the audience see verify_iss
  # config.verify_aud = nil

  # The subject of the token
  # config.subject = nil

  # Verification of the subject see verify_iss
  # config.verify_sub = nil



  # The length of the JTI hex string
  # config.jti_hex_length = 6

  # Whether to always refresh the user on refresh token
  # config.user_refresh_always = false

  # Conversion of user to json when casting payload
  # config.user_to_json_proc = proc { |user| user.as_json }

  # Conversion user from payload, keys are symbolized
  # config.user_from_json_proc = proc { |hash| User.new(**hash) }

  # Resolution of refreshed user when payload['user'] is reckognized as outdated
  # config.user_refresh_proc = proc { |json| User.find(json['id']) }
end
