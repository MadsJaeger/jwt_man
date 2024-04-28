# frozen_string_literal: true

module JwtMan
  ##
  # For a given payload it is determined wheter to refresh the uset or not. If it should refresh a new jwt and token
  # pair is encoded. Refresh is excpected to take palce only if the user_id is in the UserRefreshList. If the user has
  # not changed and refresh! is requested the old payload is used to encode the new jwt and token pair.
  class Refreshor
    def initialize(payload)
      @old_payload = payload
    end

    def user
      @user ||= if Config.user_refresh_always || refresh?
                  Config.user_refresh_proc.call(@old_payload[:user])
                else
                  Config.user_from_json_proc.call(@old_payload[:user].symbolize_keys)
                end
    end

    def refresh?
      @refresh ||= UserRefreshList.include? @old_payload.user['id']
    end

    def refresh!
      if refresh? || Config.user_refresh_always
        usr = user
        UserRefreshList >> usr.id
        oat = Time.zone.now
      else
        usr = @old_payload[:user]
        oat = Time.zone.at(@old_payload[:oat])
      end

      @encode = Encode.new(usr, oat: oat, **@old_payload.except(*Payload::RESERVED_KEYS))

      self
    end

    delegate :jwt, :token, :payload, :refresh_token, to: :@encode, allow_nil: true
  end
end
