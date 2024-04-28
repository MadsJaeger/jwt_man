class User < ApplicationRecord
  after_destroy do
    JwtMan::UserObserver.new(id).destroy_tokens
  end

  after_commit do
    JwtMan::UserObserver.new(id).add_to_refresh_list if persisted?
  end
end
