require 'rails_helper'

RSpec.describe JwtMan::Refreshor do
  let(:user) { build(:user, id: 1, email: 'mhj@mail.now') }
  let(:payload) { JwtMan::Payload.new(user: user) }
  let(:refreshor) { described_class.new(payload) }

  describe '#user' do
    subject(:usr) { refreshor.user }

    context 'when Config.user_refresh_always is true' do
      before { JwtMan.config.user_refresh_always = true }

      it 'calls Config.user_refresh_proc with the old user' do
        expect(JwtMan.config.user_refresh_proc).to receive(:call).with(payload[:user])
        usr
      end
    end

    context 'when Config.user_refresh_always is false' do
      before { JwtMan.config.user_refresh_always = false }

      context 'when refresh? is true' do
        before { allow(refreshor).to receive(:refresh?).and_return(true) }

        it 'calls Config.user_refresh_proc with the old user' do
          expect(JwtMan.config.user_refresh_proc).to receive(:call).with(payload[:user])
          usr
        end
      end

      context 'when refresh? is false' do
        before { allow(refreshor).to receive(:refresh?).and_return(false) }

        it 'calls Config.user_from_json_proc with the old user' do
          expect(JwtMan.config.user_from_json_proc).to receive(:call).with(payload[:user].symbolize_keys)
          usr
        end
      end
    end
  end

  describe '#refresh?' do
    subject { refreshor.refresh? }

    it { is_expected.to be false }

    it 'is true when the user is in the UserRefreshList' do
      JwtMan::UserRefreshList << user.id
      expect(refreshor.refresh?).to be true
    end
  end

  describe '#refresh!' do
    subject(:refresh!) { refreshor.refresh! }

    it 'calls Encode.new' do
      expect(JwtMan::Encode).to receive(:new)
      refresh!
    end

    it 'returns self' do
      expect(refresh!).to be refreshor
    end

    it 'sets a jwt' do
      expect(refresh!.jwt).to be_a String
    end

    it 'sets a token' do
      expect(refresh!.token).to be_a String
    end
  end
end
