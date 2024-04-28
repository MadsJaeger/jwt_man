require 'rails_helper'

RSpec.describe JwtMan::RefreshToken do
  include_examples 'JTI List', JwtMan::Config.refresh_token_duration, JwtMan::Config.grace_period

  subject(:refresh_token) { described_class.new(user_id: user_id, jti: jti) }

  let(:user_id) { 1 }
  let(:jti) { JwtMan::Jti.new(user_id) }

  describe '.find_by' do
    before { refresh_token.save }

    it 'returns nil when token is incorrect' do
      expect(described_class.find_by(user_id: user_id, jti: jti, token: 'faulty_token')).to be_nil
    end

    it 'returns refresh token when token is correct' do
      expect(described_class.find_by(user_id: user_id, jti: jti, token: refresh_token.token)).to eq refresh_token
    end
  end

  describe '#token' do
    subject(:token) { refresh_token.token }

    it 'is a rather complex string' do
      expect(token).to match(/\A[a-zA-Z0-9\-_]+\z/)
    end

    it 'is unique' do
      allow(SecureRandom).to receive(:uuid).and_return(:should_be_unique)
      expect(token).to eq :should_be_unique
    end

    it 'is rather long' do
      expect(token.size).to be > 20
    end
  end

  describe '#encrypted_token' do
    subject(:encrypted_token) { refresh_token.encrypted_token }

    it 'is different from token' do
      expect(encrypted_token).not_to eq refresh_token.token
    end

    it 'is a SHA256 hash' do
      expect(encrypted_token).to match(/\A[a-f0-9]{64}\z/)
    end
  end
end
