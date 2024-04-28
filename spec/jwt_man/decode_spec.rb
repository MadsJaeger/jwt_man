require 'rails_helper'

RSpec.describe JwtMan::Decode do
  subject(:decode) { described_class.new(jwt: jwt, token: token) }

  let(:user) { create(:user, id: 1, email: 'email@here.now') }
  let(:encoder) { JwtMan::Encode.new(user).tap(&:token) }
  let(:token) { encoder.token }
  let(:jwt) { encoder.jwt }

  describe '.options' do
    before do
      JwtMan.configure do |config|
        config.grace_period = 8.seconds
        config.exp_leeway = 10.seconds
        config.verify_jti = true
        config.issuer     = 'issuer'
        config.verify_iss = 'issuer'
        config.audience   = 'audience'
        config.verify_aud = 'audience'
        config.subject    = 'subject'
        config.verify_sub = 'subject'
      end
    end

    it 'holds decode options' do
      expect(described_class.options.except(:verify_jti)).to eq({
        algorithm: 'HS256',
        required_claims: %w[exp iat jti user oat iss aud sub],
        verifiy_expiration: true,
        exp_leeway: 10.seconds.to_i,
        verify_iat: true,
        verify_iss: true,
        iss: 'issuer',
        verify_aud: true,
        aud: 'audience',
        verify_sub: true,
        sub: 'subject',
      })
    end
  end

  describe 'Base-case, decoding a valid jwt and token' do
    describe '#payload' do
      it 'is the same as the encoded' do
        expect(decode.payload).to eq encoder.payload.to_h
      end
    end

    describe '#header' do
      subject { decode.header }

      it { is_expected.to eq({ alg: 'HS256' }) }
    end

    describe '#token' do
      it 'has not been refreshed' do
        expect(decode.token).to eq token
      end
    end

    describe '#jwt' do
      it 'has not been refreshed' do
        expect(decode.jwt).to eq jwt
      end
    end

    describe '#jti' do
      it 'is the same as from encoded' do
        expect(decode.jti).to eq encoder.jti
      end
    end

    describe '#user' do
      subject(:xuser) { decode.user }

      it { is_expected.to be_a(User) }

      it 'returns the user' do
        expect(xuser).to eq user
      end

      it 'config.user_from_json_proc has been called' do
        allow(JwtMan.config.user_from_json_proc).to receive(:call).and_return(:replay)
        expect(xuser).to be :replay
      end
    end

    describe '#refresh_token' do
      subject(:refresh_token) { decode.refresh_token }

      it { is_expected.to be_a(JwtMan::RefreshToken) }
    end

    describe '#verify_refresh_token!' do
      it 'returns truthy' do
        expect(decode.verify_refresh_token!).to be_truthy
      end
    end

    describe '#refresh' do
      it 'returns self' do
        expect(decode.refresh).to be decode
      end

      it 'class Encode' do
        expect(JwtMan::Encode).to receive(:new).and_call_original
        decode
      end

      it 'has a new token' do
        expect(decode.refresh.token).not_to eq token
      end

      it 'has a new jwt' do
        expect(decode.refresh.jwt).not_to eq jwt
      end

      it 'destroys the old refresh token with grace' do
        decode.refresh
        Timecop.travel(JwtMan.config.grace_period.from_now) do
          expect(JwtMan::RefreshToken.find_by(user_id: user.id, jti: encoder.jti, token: token)).to be_nil
        end
      end

      it 'can be replayed in grace period' do
        decode.refresh
        expect(described_class.new(jwt: jwt, token: token).jwt).to eq jwt
      end
    end

    describe 'repeating decode' do
      it 'can be replayed' do
        decode
        expect(described_class.new(jwt: jwt, token: token).jwt).to eq jwt
      end
    end

    describe 'without a token' do
      it 'succeeds in duration' do
        expect(described_class.new(jwt: jwt, token: nil).jwt).to eq jwt
      end

      it 'breaks with additional verification' do
        expect { described_class.new(jwt: jwt, token: nil).verify_refresh_token! }.to raise_error(JWT::RefreshTokenNotFound)
      end
    end
  end

  describe 'Breaking upon configuration' do
    context 'when issuer is wrong' do
      it 'raises JWT::InvalidIssuerError' do
        JwtMan.configure do |config|
          config.verify_iss = 'dummy'
          config.issuer = 'someone else'
        end
        expect { decode }.to raise_error(JWT::InvalidIssuerError)
      end
    end

    context 'when audience is wrong' do
      it 'raises JWT::InvalidAudError' do
        described_class.options[:aud] = 'someone else'
        described_class.options[:verify_aud] = true
        expect { decode }.to raise_error(JWT::InvalidAudError)
      end
    end

    context 'when subject is wrong' do
      it 'raises JWT::InvalidSubError' do
        described_class.options[:sub] = 'someone else'
        described_class.options[:verify_sub] = true
        expect { decode }.to raise_error(JWT::InvalidSubError)
      end
    end

    context 'when algorithm is wrong' do
      it 'raises JWT::IncorrectAlgorithm' do
        described_class.options[:algorithm] = 'HS512'
        expect { decode }.to raise_error(JWT::IncorrectAlgorithm)
      end
    end

    context 'when secret has changed' do
      it 'raises JWT::VerificationError' do
        encoder
        allow(JwtMan::Config).to receive(:secret).and_return('wrong')
        expect { decode }.to raise_error(JWT::VerificationError)
      end
    end

    context 'when a required claim is missing' do
      ##
      # Dont let verification break before missing required claims
      before do
        JwtMan.configure do |config|
          config.verify_iss = nil
          config.verify_aud = nil
          config.verify_sub = nil
          config.issuer     = nil
          config.audience   = nil
          config.subject    = nil
        end
      end

      it 'raises JWT::MissingRequiredClaim' do
        payload_stub = double('payload', { user: user.as_json })
        allow(payload_stub).to receive(:jti).and_return('abc')
        allow(payload_stub).to receive(:iat).and_return(Time.zone.now)
        allow_any_instance_of(JwtMan::Encode).to receive(:payload).and_return(payload_stub)

        expect { decode }.to raise_error(JWT::MissingRequiredClaim)
      end
    end

    context 'when iat is in the future' do
      it 'raises JWT::InvalidIatError' do
        allow_any_instance_of(JwtMan::Payload).to receive(:iat).and_return(Time.now + 10.seconds)
        expect { decode }.to raise_error(JWT::InvalidIatError)
      end
    end

    context 'when iat is not a number' do
      it 'raises JWT::InvalidPayload' do
        allow_any_instance_of(JwtMan::Encode).to receive(:payload).and_return({ iat: 'not a number' })

        expect { decode }.to raise_error(JWT::InvalidPayload)
      end
    end

    context 'when the jwt is nonsense' do
      let(:jwt) { 'nonsense' }

      it 'raises JWT::DecodeError' do
        expect { decode }.to raise_error(JWT::DecodeError)
      end
    end

    context 'with verify_jti' do
      it 'raises JWT::InvalidJtiError when blacklisted' do
        JwtMan.configure do |config|
          config.verify_jti = true
        end
        JwtMan::Blacklist.create!(jti: encoder.jti, user_id: user.id)

        expect { decode }.to raise_error(JWT::InvalidJtiError)
      end
    end
  end

  describe 'Refreshing JWT and token' do
    context 'when exp_leeway has been set' do
      before do
        JwtMan.configure do |config|
          config.exp_leeway = 5.seconds
        end
      end

      it 'does not refresh jwt during leeway' do
        encoder
        Timecop.travel((JwtMan.config.duration + 2.seconds).from_now) do
          expect(decode.jwt).to eq jwt
        end
      end

      it 'does not refresh token during leeway' do
        encoder
        Timecop.travel((JwtMan.config.duration + 2.seconds).from_now) do
          expect(decode.token).to eq token
        end
      end

      it 'refreshes jwt after leeway' do
        encoder
        Timecop.travel((JwtMan.config.duration + 5.seconds).from_now) do
          expect(decode.jwt).not_to eq jwt
        end
      end

      it 'refreshes token after leeway' do
        encoder
        Timecop.travel((JwtMan.config.duration + 5.seconds).from_now) do
          expect(decode.token).not_to eq token
        end
      end
    end

    context 'when the jwt is expired' do
      before do
        encoder
        Timecop.travel(JwtMan.config.duration.from_now + 1.second)
      end

      it 'returns a new jwt' do
        expect(decode.jwt).not_to eq jwt
      end

      it 'returns a new token' do
        expect(decode.token).not_to eq token
      end

      it 'does not change the oat' do
        expect(decode.payload[:oat]).to eq encoder.payload[:oat]
      end

      it 'can be replayed immediately' do
        new_jwt = decode.jwt
        expect(described_class.new(jwt: jwt, token: token).jwt).not_to eq new_jwt
      end

      it 'cannot be replayed after grace period' do
        decode
        Timecop.travel(JwtMan.config.grace_period.from_now) do
          expect { described_class.new(jwt: jwt,token: token)}.to raise_error(JWT::RefreshTokenNotFound)
        end
      end
    end

    context 'when the token is expired' do
      before { encoder }

      it 'raises JWT::RefreshTokenNotFound' do
        Timecop.travel(JwtMan.config.refresh_token_duration.from_now + 1.second) do
          expect { decode }.to raise_error(JWT::RefreshTokenNotFound)
        end
      end
    end
  end

  describe 'Updating the user' do
    context 'with config.user_refresh_always' do
      before do
        JwtMan.configure do |config|
          config.user_refresh_always = true
        end
        encoder
      end

      it 'User recieves #find when user is requested' do
        expect(User).to receive(:find).with(user.id).and_call_original
        decode.user
      end

      it 'does not change the jwt' do
        Timecop.travel(1.second.from_now) do
          expect(decode.jwt).to eq jwt
        end
      end

      it 'does not issue a new refresh token' do
        expect { decode }.not_to change(JwtMan::RefreshToken, :count)
      end
    end

    context 'when user has been destroyed' do
      it 'raises JWT::RefreshTokenNotFound due to user callback' do
        encoder
        user.destroy!
        expect { decode }.to raise_error(JWT::RefreshTokenNotFound)
      end
    end

    context 'when user has been updated' do
      before do
        encoder
        user.update!(email: 'new@maile.here')
      end

      it 'user has been placed in refresh list' do
        expect(JwtMan::UserRefreshList).to include(user.id)
      end

      it 'updates oat' do
        Timecop.travel(1.second.from_now) do
          expect(decode.payload[:oat]).to be > encoder.payload[:oat]
        end
      end

      it 'changes the jwt' do
        Timecop.travel(1.second.from_now) do
          expect(decode.jwt).to_not eq jwt
        end
      end

      it 'issues a new refresh token' do
        expect { decode.token }.to change(JwtMan::RefreshToken, :count).by(1)
      end

      it 'pops the user from the refreshlist' do
        expect { decode }.to change(JwtMan::UserRefreshList, :size).by(-1)
      end

      it 'returns the updated user' do
        expect(decode.user.email).to eq 'new@maile.here'
      end

      it 'User recieved :find' do
        expect(User).to receive(:find).and_call_original
        decode
      end
    end
  end

  describe 'Maintianitng payload' do
    let(:encoder) { JwtMan::Encode.new(user, foo: 'bar').tap(&:token) }
    let(:decode) { described_class.new(jwt: jwt, token: token).tap(&:refresh) }

    it 'holds the inital payload' do
      expect(decode.payload).to include({foo: 'bar'})
    end

    it 'refreshes with the inital payload' do
      second = described_class.new(jwt: decode.jwt, token: decode.token)
      expect(second.payload).to include({foo: 'bar'})
    end
  end
end
