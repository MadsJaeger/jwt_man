# frozen_string_literal: true

module JwtMan
  ##
  # Observation of a user changed event. This can be used to flag users for update in the decode process. A user_id will
  # be added to the refresh list, if the user has any refresh tokens. Othwerwise it is not relevant.
  class UserObserver
    def initialize(user_id)
      @user_id = user_id
    end

    def destroy_tokens
      add_to_refresh_list
      RefreshToken.where(user_id: @user_id).each(&:destroy_now)
    end

    def add_to_refresh_list
      UserRefreshList << @user_id if in_refresh_tokens?
    end

    def in_refresh_tokens?
      RefreshToken.any_for?(user_id: @user_id)
    end
  end
end
