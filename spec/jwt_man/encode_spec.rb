require 'rails_helper'

RSpec.describe JwtMan::Encode do
  let(:user) { build(:user, id: 1) }
  let(:encoder) { described_class.new(user) }

  describe '#initialize' do
    it 'creates a new instance' do
      expect(encoder).to be_a(described_class)
    end

    it 'sets the user' do
      expect(encoder.user).to be(user)
    end

    it 'send the kwargs the payload' do
      expect(JwtMan::Payload).to receive(:new).with(user: user, foo: 'bar')
      described_class.new(user, foo: 'bar')
    end
  end

  describe '#encode' do
    subject(:encode) { encoder.encode }

    it 'returns the JWT token' do
      expect(encode).to be encoder.jwt
    end
  end

  describe '#jwt' do
    it 'returns the JWT token' do
      expect(encoder.jwt).to match /^[\w-]*\.[\w-]*\.[\w-]*$/
    end
  end

  describe '#payload' do
    it 'creates a payload' do
      expect(encoder.payload).to be_a(JwtMan::Payload)
    end
  end

  describe '#jti' do
    it 'returns the jti' do
      expect(encoder.jti).to be_a(JwtMan::Jti)
    end
  end

  describe '#token' do
    it 'returns a string' do
      expect(encoder.token).to be_a(String)
    end

    it 'calls the #refresh_token' do
      expect(encoder).to receive_message_chain(:refresh_token, :token).and_return('token')
      expect(encoder.token).to eq('token')
    end
  end

  describe '#refresh_token' do
    it 'returns the refresh token' do
      expect(encoder.send(:refresh_token)).to be_a(JwtMan::RefreshToken)
    end
  end
end
