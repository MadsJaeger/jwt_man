require 'rails_helper'

RSpec.describe JwtMan::UserObserver do
  subject(:observer) { described_class.new(user_id) }

  let(:user_id) { 1 }

  describe '#destroy_tokens' do
    subject(:destroy_tokens) { observer.destroy_tokens }

    context 'when user has refresh tokens' do
      it 'does not change the refresh list' do
        expect { destroy_tokens }.not_to change { JwtMan::UserRefreshList.size }
      end

      it 'does not change the refresh tokens' do
        expect { destroy_tokens }.not_to change { JwtMan::RefreshToken.count }
      end
    end

    context 'when user does not have refresh tokens' do
      before do
        ['a', 'b', 'c'].each do |jti|
          JwtMan::RefreshToken.create!(user_id: user_id, jti: jti)
        end
      end

      it 'changes the refresh list' do
        expect { destroy_tokens }.to change { JwtMan::UserRefreshList.size }.from(0).to(1)
      end

      it 'destroys the refresh tokens' do
        expect { destroy_tokens }.to change { JwtMan::RefreshToken.count }.from(3).to(0)
      end

      it 'is included in the refresh list' do
        expect { destroy_tokens }.to change { JwtMan::UserRefreshList.include?(user_id) }.from(false).to(true)
      end

      it 'is idempotent' do
        destroy_tokens
        expect { destroy_tokens }.not_to change { JwtMan::UserRefreshList.size }
      end
    end
  end

  describe '#add_to_refresh_list' do
    subject(:add_to_refresh_list) { observer.add_to_refresh_list }

    context 'when user does not have refresh tokens' do
      it 'does not change the refresh list' do
        expect { add_to_refresh_list }.not_to change { JwtMan::UserRefreshList.size }
      end

      it 'is not included in the refresh list' do
        expect { add_to_refresh_list }.not_to change { JwtMan::UserRefreshList.include?(user_id) }.from(false)
      end
    end

    context 'when user has refresh tokens' do
      before { JwtMan::RefreshToken.create!(user_id: user_id, jti: 'a')}

      it 'adds the user to the refresh list' do
        expect { add_to_refresh_list }.to change(JwtMan::UserRefreshList, :size).from(0).to(1)
      end

      it 'is idempotent' do
        add_to_refresh_list
        expect { add_to_refresh_list }.to_not change(JwtMan::UserRefreshList, :size)
      end

      it 'is included in the refresh list' do
        expect { add_to_refresh_list }.to change { JwtMan::UserRefreshList.include?(user_id) }.from(false).to(true)
      end
    end
  end

  describe '#in_refresh_tokens?' do
    subject(:in_refresh_tokens?) { observer.in_refresh_tokens? }

    it { is_expected.to be false }

    it 'is true when user has refresh tokens' do
      JwtMan::RefreshToken.create!(user_id: user_id, jti: 'a')
      expect(observer.in_refresh_tokens?).to be_truthy
    end
  end
end
