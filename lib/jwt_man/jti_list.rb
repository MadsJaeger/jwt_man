# frozen_string_literal: true

module JwtMan
  ##
  # Abstract class for JTI tokens with a Redis backend. Intended to Mimicks ActiveRecord, to let them be used
  # interchangeably in the future.
  class JtiList
    class << self
      def key
        raise NotImplementedError, 'JtiList is an abstract class'
      end

      def create(user_id:, jti:, exp: nil)
        new(user_id: user_id, jti: jti, exp: exp).tap(&:save)
      end
      alias create! create

      def any_for?(user_id:)
        matcher = "#{key}_#{user_id}_*"
        found   = nil
        cursor  = 0
        until found
          cursor, list = redis.scan(cursor, match: matcher)
          return list unless list.empty?
          break if cursor.to_i.zero?
        end

        false
      end

      def find_by(user_id: nil, jti: nil)
        return nil if user_id.blank? && jti.blank?
        return new(user_id: user_id, jti: jti) if user_id && jti && redis.exists?("#{key}_#{user_id}_#{jti}")

        matcher = "#{key}_#{user_id || '*'}_#{jti || '*'}"
        found   = nil
        cursor  = 0
        until found
          cursor, list = redis.scan(cursor, match: matcher)
          found = list.first
          break if cursor.to_i.zero?
        end
        return nil if found.blank?

        _pre, user_id, jti = found.split('_')

        new(user_id: user_id, jti: found.split('_').last)
      end

      def where(user_id: nil, jti: nil)
        return CollectionDuck.new([find_by(user_id: user_id, jti: jti)].compact) if (user_id && jti) || jti

        matcher = "#{key}_#{user_id || '*'}_#{jti || '*'}"
        keys    = redis.scan_each(match: matcher).map(&:itself)
        records = keys.map do |key|
          _pre, user_id, jti = key.split('_')
          new(user_id: user_id, jti: jti)
        end
        CollectionDuck.new(records)
      end

      def count
        keys.size
      end

      def keys
        Config.redis.scan_each(match: "#{key}_*").map(&:itself)
      end

      def all
        where
      end

      private

      delegate :redis, to: Config
    end

    attr_accessor :user_id, :jti
    attr_writer :exp

    def initialize(user_id:, jti:, exp: nil)
      self.user_id = user_id
      self.jti     = jti
      self.exp     = exp
    end

    def key
      "#{self.class.key}_#{user_id}_#{jti}"
    end

    def ==(other)
      other.is_a?(self.class) && (other.key == key)
    end

    def save
      redis.set(key, data, exat: to_expire_at.to_i + 1) == 'OK'
    end

    def destroy
      redis.del(key) == 1
    end
    alias destroy! destroy

    def saved?
      redis.exists?(key)
    end

    def expire(duration)
      if duration.is_a?(Time) || duration.is_a?(DateTime)
        redis.expireat(key, duration.to_i)
      else
        redis.expire(key, duration.to_i)
      end
    end

    def pttl
      redis.pttl(key)
    end

    def exp
      if saved? && pttl
        Time.zone.at((Time.zone.now + (pttl.to_f / 1_000).seconds).to_i)
      else
        to_expire_at
      end
    end

    private

    def data
      true
    end

    def to_expire_at
      @exp ||= Time.zone.now.floor + duration
    end

    def duration
      Config.duration
    end

    delegate :redis, to: Config
  end
end
