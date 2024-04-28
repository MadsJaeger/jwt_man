require 'rails_helper'

RSpec.describe JwtMan::Payload do
  subject(:payload) { described_class.new(user: user) }

  let(:user) { build(:user, id: 1, email: 'mhj@mail.ok') }

  it { is_expected.to be_a(Hash) }

  it 'is simple' do
    allow(JwtMan::Jti).to receive(:new).and_return('jti')

    Timecop.freeze do
      expect(described_class.new(user: user)).to eq({
        oat: Time.zone.now.floor.to_i,
        iat: Time.zone.now.floor.to_i,
        exp: (Time.zone.now.floor + JwtMan::Config.duration).to_i,
        jti: 'jti',
        user: user.as_json
      })
    end
  end

  describe '#initialize' do
    let(:payload) do
      described_class.new(
        user: user,
        oat: Time.new(2019, 1, 1, 0, 0, 0, '+00:00'),
        iat: Time.new(2019, 1, 2, 0, 0, 0, '+00:00'),
        exp: Time.new(2000, 1, 1, 0, 0, 0, '+00:00'),
        foo: 'bar',
        iss: 'EvilCorp',
        add: [1, 2, 3]
      )
    end

    it 'can be controlled by kwargs' do
      allow(JwtMan::Jti).to receive(:new).and_return('abc')

      expect(payload).to eq({
        add: [1, 2, 3],
        exp: 946684800,
        foo: "bar",
        iat: 1546387200,
        iss: "EvilCorp",
        jti: "abc",
        oat: 1546300800,
        user: user.as_json
      })
    end
  end

  describe '#oat' do
    subject { payload.oat }

    it { is_expected.to be_a(Time) }
    it { is_expected.to eq(payload.iat) }

    it 'can be set on init' do
      oat = Time.zone.now.floor - 1.day
      expect(described_class.new(user: user, oat: oat).oat).to eq(oat)
    end

    it 'can be set after init' do
      oat = Time.zone.now.floor - 1.day
      payload.oat = oat
      expect(payload.oat).to eq(oat)
    end
  end

  describe '#iat' do
    subject { payload.iat }

    it { is_expected.to be_a(Time) }
    it { is_expected.to eq(Time.zone.now.floor) }
    it { is_expected.to be < payload.exp }

    it 'can be set on init' do
      iat = Time.zone.now.floor - 1.day
      expect(described_class.new(user: user, iat: iat).iat).to eq(iat)
    end

    it 'can be set after init' do
      iat = Time.zone.now.floor - 1.day
      payload.iat = iat
      expect(payload.iat).to eq(iat)
    end
  end

  describe '#exp' do
    subject { payload.exp }

    before { JwtMan.config.duration = 10.seconds }

    it { is_expected.to be_a(Time) }
    it { is_expected.to be_within(1.second).of(payload.iat + 10.seconds) }
    it { is_expected.to be > payload.iat }
  end

  describe '#iss' do
    subject { payload.iss }

    it { is_expected.to be_a_nil }

    context 'when config.issuer is set' do
      before { JwtMan.config.issuer = 'DummyApp' }

      it { is_expected.to eq('DummyApp') }
    end
  end

  describe '#aud' do
    subject { payload.aud }

    it { is_expected.to be_a_nil }

    context 'when config.audience is set' do
      before { JwtMan.config.audience = 'OtherApp' }

      it { is_expected.to eq('OtherApp') }
    end
  end

  describe '#sub' do
    subject { payload.sub }

    it { is_expected.to be_a_nil }

    context 'when config.subject is set' do
      before { JwtMan.config.subject = 'User' }

      it { is_expected.to eq('User') }
    end
  end

  describe '#jti' do
    subject { payload.jti }

    it { is_expected.to be_a(String) }
    it { is_expected.to be_a(JwtMan::Jti) }
    it { is_expected.to match(/\A[a-zA-Z0-9\-_]+\z/) }
  end

  describe '#to_h' do
    subject(:to_h) { payload.to_h }

    it { is_expected.to be_a(Hash) }

    it 'holds :oat' do
      expect(to_h[:oat]).to eq(payload.oat.to_i)
    end

    it 'holds :iat' do
      expect(to_h[:iat]).to eq(payload.iat.to_i)
    end

    it 'holds :exp' do
      expect(to_h[:exp]).to eq(payload.exp.to_i)
    end

    it { is_expected.not_to include(:iss) }

    context 'when config.issuer is set' do
      before { JwtMan.config.issuer = 'DummyApp' }

      it 'holds :iss' do
        expect(to_h[:iss]).to eq('DummyApp')
      end
    end

    it { is_expected.not_to include(:aud) }

    context 'when config.audience is set' do
      before { JwtMan.config.audience = 'OtherApp' }

      it 'holds :aud' do
        expect(to_h[:aud]).to eq('OtherApp')
      end
    end

    it { is_expected.not_to include(:sub) }

    context 'when config.subject is set' do
      before { JwtMan.config.subject = 'User' }

      it 'holds :sub' do
        expect(to_h[:sub]).to eq('User')
      end
    end

    it 'holds :jti' do
      expect(to_h[:jti]).to eq(payload.jti)
    end

    describe '[:user]' do
      subject(:json_user) { to_h[:user] }

      it { is_expected.to be_a(Hash) }
      it 'has :id' do
        expect(json_user['id']).to eq(user.id)
      end

      it 'has :email' do
        expect(json_user['email']).to eq(user.email)
      end

      it 'calls config.user_to_json_proc' do
        expect(JwtMan.config.user_to_json_proc).to receive(:call).with(user)
        json_user
      end
    end
  end
end
