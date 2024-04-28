require 'rails_helper'

RSpec.describe JwtMan::UserRefreshList do
  let(:redis) { JwtMan::Config.redis }

  after { described_class.clear! }

  describe '.size' do
    subject(:size) { described_class.size }

    it { is_expected.to be 0 }

    it 'is increased when a user is added' do
      described_class << 1
      expect(size).to be 1
    end

    it 'is decreased when a user is removed' do
      described_class << 1
      described_class >> 1
      expect(size).to be 0
    end
  end

  describe '.clear!' do
    before { described_class << [1, 2, 3, 4] }

    it 'removes all users from the list' do
      expect { described_class.clear! }.to change(described_class, :size).from(4).to(0)
    end
  end

  describe '.to_a' do
    subject(:to_a) { described_class.to_a }

    it { is_expected.to eq [] }

    it 'returns the list of users' do
      described_class << [1, 2, 3, 4]
      expect(described_class.to_a.sort).to eq [1, 2, 3, 4]
    end
  end

  describe '.<<' do
    subject(:add) { described_class << 1 }

    it 'adds the user_od to the list' do
      expect { add }.to change(described_class, :size).from(0).to(1)
    end

    it 'does not re-add the user to the list' do
      add
      expect { add }.not_to(change(described_class, :size))
    end
  end

  describe '.+' do
    subject(:add) { described_class + [1, 2] }

    it 'adds the users to the list' do
      expect { add }.to change(described_class, :size).from(0).to(2)
    end

    it 'does not re-add the users to the list' do
      add
      expect { add }.not_to(change(described_class, :size))
    end

    it 'adds new users to the list' do
      add
      expect { described_class + [2, 3] }.to change(described_class, :size).from(2).to(3)
    end
  end

  describe '.>>' do
    subject(:remove) { described_class >> 1 }

    before { described_class << 1 }

    it 'removes the user from the list' do
      expect { remove }.to change(described_class, :size).from(1).to(0)
    end

    it 'does not re-remove the user from the list' do
      remove
      expect { remove }.not_to change(described_class, :size)
    end

    it 'does not remove non existing users from the list' do
      expect { described_class >> 2 }.not_to(change(described_class, :size))
    end
  end

  describe '.-' do
    subject(:remove) { described_class - [1, 2] }

    before { described_class + [1, 2, 3] }

    it 'removes the users from the list' do
      expect { remove }.to change(described_class, :size).from(3).to(1)
    end

    it 'does not re-remove the users from the list' do
      remove
      expect { remove }.not_to(change(described_class, :size))
    end

    it 'does not remove non existing users from the list' do
      expect { described_class - [3, 4] }.to change(described_class, :size).from(3).to(2)
    end
  end

  describe '.include?' do
    before { described_class << 1 }

    it 'returns true when the user is in the list' do
      expect(described_class.include?(1)).to be true
    end

    it 'returns false when the user is not in the list' do
      expect(described_class.include?(2)).to be false
    end
  end
end
