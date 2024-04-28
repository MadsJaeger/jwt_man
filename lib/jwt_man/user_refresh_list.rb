# frozen_string_literal: true

module JwtMan
  ##
  # List of users that have been marked for refresh. Users will normally by instantiated from the jwt using the
  # user_from_json_proc. However, if the user is in the refresh list, the user ought to be fetched from the database.
  # This is in order to allow users, their rights, roles etc to be updated in the database and reflected in the jwt.
  module UserRefreshList
    KEY = 'user_refresh_list'

    module_function

    def redis
      Config.redis
    end

    def to_a
      redis.smembers(KEY).map(&:to_i)
    end

    def clear!
      redis.del KEY
    end

    def <<(other)
      redis.sadd KEY, other
    end

    def +(other)
      redis.sadd KEY, other
    end

    def >>(other)
      redis.srem KEY, other
    end

    def -(other)
      redis.srem KEY, other
    end

    def size
      redis.scard KEY
    end

    def include?(other)
      redis.sismember KEY, other
    end
  end
end
