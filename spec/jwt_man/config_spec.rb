require 'rails_helper'

RSpec.describe JwtMan::Config do
  describe 'configure' do
    it 'yields JwtMan::Config' do
      expect { |b| described_class.configure(&b) }.to yield_with_args(described_class)
    end

    it 'sets the duration' do
      described_class.configure { |c| c.duration = 1.hour }
      expect(described_class.duration).to eq 1.hour
    end
  end

  describe 'redis' do
    it 'is a Redis instance' do
      expect(described_class.redis).to be_a MockRedis
    end

    it 'can be changed' do
      described_class.redis = 'my redis'
      expect(described_class.redis).to eq 'my redis'
    end
  end

  describe 'secret' do
    it 'raises an error if not set' do
      described_class.secret = nil
      expect { described_class.secret }.to raise_error ArgumentError, 'JwtMan: secret must be set'
    end

    it 'is a string value' do
      expect(described_class.secret).to be_a String
    end

    it 'can be changed' do
      described_class.secret = 'my secret'
      expect(described_class.secret).to eq 'my secret'
    end
  end

  {
    duration: [15.minutes, 1.hour],
    algorithm: ['HS256', 'HS512'],
    exp_leeway: [0, 1],
    issuer: [nil, 'my app'],
    verify_iss: [nil, 'dummy'],
    audience: [nil, 'other app'],
    verify_aud: [nil, 'other app'],
    subject: [nil, 'user'],
    jti_hex_length: [6, 32],
    refresh_token_duration: [3.months, 1.year],
    grace_period: [8.seconds, 10.seconds],
    user_refresh_always: [false, true],
  }.each do |method, (default, new_value)|
    describe method.to_s do
      it 'can be changed' do
        expect {
          described_class.send("#{method}=", new_value)
        }.to change {
          described_class.send(method)
        }.from(default).to(new_value)
      end
    end
  end

  describe 'user_to_json_proc' do
    it 'calls as json on the user' do
      user = double(:user)
      expect(user).to receive(:as_json)
      described_class.user_to_json_proc.call(user)
    end
  end

  describe 'user_from_json_proc' do
    it 'calls new on the user class' do
      expect(User).to receive(:new).with(id: 1)
      described_class.user_from_json_proc.call({id: 1})
    end
  end

  describe 'user_refresh_proc' do
    it 'calls find on the user class' do
      expect(User).to receive(:find).with(1)
      described_class.user_refresh_proc.call({id: 1}.as_json)
    end
  end
end
