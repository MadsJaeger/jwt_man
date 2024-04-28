# JwtMan
The purpose of JwtMan is to provide a full plugable JWT implementation with refresh tokens for a Rails application. It builds on the `gem 'jwt'` by adding an abstraction to the library leaving the ussage of it configurable. Additionally, to JWT generation refresh tokens will be issued allowing users to obtain a new JWT after expiration. This allows to adhere to the common recomondation of having a short lived JWTs yet granting users possible infinte sessions. Using refreshability is particularly useful for Rails api-only projects that are sessionless and whose common client is a web application. The web application ought not to store the JWT in session or local storage as it leaves it voulnable to XSS attacks; however, storing the JWT in a HTTP only cookie opens for CSRF attacks. CSRF attacks are not protected against in a Rails api only project and enabling it may cause some useability issues. Instead, by communicating the JWT in a cookie and the refresh token in the header and validating it the token upon none GET requests, this gem offers the needed CSRF protection without a session. Besides offering refresh tokens JwtMan comes with a blicklist strategy allowing you to revoke issued JWTs. Also, it comes with a system to allow the user the be initialized from the JWT saving a database transaction on every authorization. In fact, we do not provide the user until reqeuested, allowing authorization and further and action to take place without touching the user until or if needed. JwtMan uses redis to store refreshtoken and blacklisted tokens making them persistable and fast whilst allowing for automatic expiration.

## Usage
The two main classes of the program are `Encode` and `Decode` who respectively issues and decrypts JWTs. To issue a new JWT encode a user:

```ruby
JwtMan.configure do |config|
  # Encryption secret
  config.secret = 'Something secure'
  # Duration of jwts
  config.duration = 15.miuntes
  # Duraiton of refresh tokens, e.g. max `sessions` length
  config.refresh_token_duration = 3.months
  # How to convert the user to json when placed in payload
  config.user_to_json_proc = proc { |user| user.as_json(only: 'relevant fields', include: 'rights') }
end

JwtMan::Encode.new(
  user,
  keyword_arguments: :to_place_in_the_payload
).tap do |enc|
  enc.jwt   # Jwt to place in HTTP only Set-Cookie
  enc.token # Refresh token to place in header
end
```

In your authorization strategy you will at some point call:

```ruby
JwtMan.configure do |config|
  # Whether to always refresh the user upon decode
  config.user_refresh_always = false
  # Conversion user from payload, keys are symbolized
  config.user_from_json_proc = proc { |hash| User.new(**hash) }
  # Resolution of refreshed user when payload['user'] is reckognized as outdated
  config.user_refresh_proc = proc { |json| User.active.find(json['id']) }
end

JwtMan::Decode.new(
  jwt: request.env['HTTP_AUTHORIZATION']
  token: request.env['HTTP_REFRESH_TOKEN']
).tap do |dec|
  dec.refreshed?            # wheter refresh took place
  dec.jwt                   # The given jwt or a refreshed jwt
  dec.token                 # The given token or a refreshed roken
  dec.payload               # Decrypted data
  dec.user                  # Lazily loaded user instance
                            #   given from user_from_json_proc unless refreshed?
                            #   given from user_refresh_proc if refreshed?
  dec.verify_refresh_token! # Verify that it still exists
end
```

Refresh will take place if the token has expired and the refresh token will be validated. Refresh may take palce before expiration if the user has been marked for refresh. This measuere is in place in order to avoid users deleted or changed to be replayed within JWT duration. To prevent CSRF attacks call `verify_refresh_token!` before action for any none GET request. Remember to always reset cookie and header to JWT and token of the decode instance.

When calling Decode.new a child of `JWT::DecodeError` or itself will be raised if we dont trust the recieved data, the user could not be found, refresh duration has elapsed, JWT has been blacklisted, claims could not be validated etc. In any case you will want to respond with 401.

In order to let the Decode instance know when a user ought to be refreshed you need to call the `UserObserver` who will list the user for refresh:

```ruby
class User < ApplicationRecord
  after_destroy do
    JwtMan::UserObserver.new(id).destroy_tokens
  end

  after_commit do
    JwtMan::UserObserver.new(id).add_to_refresh_list if persisted?
  end
end
```

Likewise if the permissions of the user changes you will probably want to do the same thing.

In order to sign out users you may either remove their refresh token or blacklist the jti. The former may be enough, especially if you `verify_refresh_token!` before non GET actions. However, this leaves get requests open on the JWT until it has expired. Notice that refresh tokens are not removed immediately upon refresh but a `config.grace_period` is given to allow simultaneous requests. To ensure the user signed out immediately you might want to blacklist the user:

```ruby
JwtMan.configure do |config|
  config.verify_jti = true
end

BlackList.create!(user_id:, jti:)
```

If you for some reason would like leverage a whitelist it is actually provided through the list of refresh tokens as theese are identified by the JTI of the jwt. Just verify the refresh token and the whitelist has been applied. 

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'jwt_man'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install jwt_man
```

To obtain a scaffold for configuration and available configuration options run:

```bash
$ rails g jwt_man:install
```

## Contributing
Contact author.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
