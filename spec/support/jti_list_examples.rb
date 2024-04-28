RSpec.shared_examples 'JTI List' do |duration, grace = 0|
  subject(:record) { described_class.create(user_id: user_id, jti: jti) }

  let(:user_id) { 1 }
  let(:jti) { 'abc' }

  def mock_jti
    10.times.map { ('a'..'z').to_a.sample }.join
  end

  describe '.key' do
    subject(:key) { described_class.key }

    it { is_expected.to be_a String }
    it { is_expected.to be_frozen }

    it 'is expected to be rather short' do
      expect(key.length).to be < 6
    end
  end

  describe '.create' do
    before { record }

    it { is_expected.to be_a described_class }
    it { is_expected.to be_saved }
    it { is_expected.to have_attributes user_id: user_id, jti: jti }

    it 'can be found by user_id and jti' do
      found = described_class.find_by(user_id: user_id, jti: jti)
      expect(found).to eq record
    end

    it 'is has incremented count' do
      expect(described_class.count).to eq 1
    end

    it 'is contained in all' do
      expect(described_class.all).to include record
    end

    it 'is contained in where' do
      expect(described_class.where(user_id: user_id, jti: jti)).to include record
    end

    it 'is contained in keys' do
      expect(described_class.keys).to include record.key
    end

    it 'can be set with exp' do
      record = described_class.create(user_id: user_id, jti: jti, exp: 1.hour.from_now)
      expect(record.exp).to be_within(1.second).of 1.hour.from_now
    end

    describe 'duplication' do
      let(:other) { described_class.create(user_id: user_id, jti: jti) }

      it 'is the same record' do
        record
        Timecop.travel(1.hour.from_now)
        expect(other).to eq record
      end
    end
  end

  describe '.create!' do
    subject { described_class }

    it { is_expected.to respond_to(:create!) }
  end

  describe '.find_by' do
    subject(:found) { described_class.find_by(user_id: user_id, jti: jti) }

    context 'when record exists' do
      before { record }

      it { is_expected.to be_a described_class }
      it { is_expected.to be_saved }
      it { is_expected.to have_attributes user_id: user_id, jti: jti }

      it 'can be found solely by jti' do
        found = described_class.find_by(jti: jti)
        expect(found).to eq record
      end

      it 'can be found solely by user_id' do
        found = described_class.find_by(user_id: user_id)
        expect(found).to eq record
      end
    end

    context 'when record does not exist' do
      it { is_expected.to be_nil }
    end

    context 'with multiple records by user_id' do
      it 'finds the first record' do
        a = described_class.create(user_id: user_id, jti: 'a')
        _b = described_class.create(user_id: user_id, jti: 'b')
        found = described_class.find_by(user_id: user_id)
        expect(found).to eq a
      end
    end
  end

  describe '.any_for(user_id:)' do
    subject(:any_for) { described_class.any_for?(user_id: user_id) }

    it { is_expected.to be false }

    it 'returns list of records for (but not every)' do
      %w[a b c].each { |jti| described_class.create(user_id: user_id, jti: jti) }
      expect(described_class.any_for?(user_id: user_id)).to eq %w[a b c].map { |jti| "#{described_class.key}_#{user_id}_#{jti}" }
    end
  end

  describe '.where' do
    subject(:found) { described_class.where(user_id: user_id, jti: jti) }

    context 'when record exists' do
      before { record }

      it { is_expected.to be_a JwtMan::CollectionDuck }

      it 'can be found solely by jti' do
        found = described_class.where(jti: jti)
        expect(found).to include record
      end

      it 'can be found solely by user_id' do
        found = described_class.where(user_id: user_id)
        expect(found).to include record
      end
    end

    context 'when record does not exist' do
      it { is_expected.to be_empty }
    end

    context 'with multiple records by user_id' do
      it 'finds all records' do
        a = described_class.create(user_id: user_id, jti: 'a')
        b = described_class.create(user_id: user_id, jti: 'b')
        found = described_class.where(user_id: user_id)
        expect(found).to include a, b
      end

      it 'does not find records of other users' do
        _a = described_class.create(user_id: user_id, jti: 'a')
        b = described_class.create(user_id: create(:user), jti: 'b')
        expect(described_class.where(user_id: user_id)).not_to include b
      end
    end
  end

  describe '.count' do
    subject(:count) { described_class.count }

    it { is_expected.to be_zero }

    it 'increments with each record' do
      expect do
        5.times { described_class.create(user_id: create(:user), jti: mock_jti) }
      end.to change(described_class, :count).by 5
    end

    it 'count decrements as items expire' do
      described_class.create(user_id: user_id, jti: jti, exp: 1.minute.from_now)
      expect do
        Timecop.travel(61.seconds.from_now)
      end.to change(described_class, :count).by(-1)
    end
  end

  describe '.keys' do
    subject(:keys) { described_class.keys }

    it { is_expected.to be_empty }
    it { is_expected.to be_a Array }

    it 'holds the keys of all records' do
      record
      other = described_class.create(user_id: user_id, jti: 'other')
      expect(keys).to eq [record.key, other.key]
    end
  end

  describe '.all' do
    it 'holds all records' do
      a = described_class.create(user_id: user_id, jti: 'a')
      b = described_class.create(user_id: user_id, jti: 'b')
      expect(described_class.all).to eq [a, b]
    end
  end

  describe '#key' do
    subject(:key) { record.key }

    it { is_expected.to be_a String }
    it { is_expected.to start_with described_class.key }
    it { is_expected.to end_with "#{user_id}_#{jti}" }
  end

  describe '#destroy' do
    context 'when record exists' do
      subject(:destroy) { record.destroy }

      before { record }

      it { is_expected.to be true }

      it 'record is no longer saved' do
        destroy
        Timecop.travel(grace.seconds.from_now) if grace
        expect(record).not_to be_saved
      end

      it 'decrements count' do
        expect do
          destroy
          Timecop.travel(grace.seconds.from_now) if grace
        end.to change(described_class, :count).by(-1)
      end

      it 'can no longe be found' do
        expect do
          destroy
          Timecop.travel(grace.seconds.from_now) if grace
        end.to change { described_class.find_by(user_id: user_id, jti: jti) }.from(record).to nil
      end
    end

    context 'when record does not exist' do
      subject(:destroy) { described_class.new(user_id: user_id, jti: jti).destroy }

      it { is_expected.to be false }
    end
  end

  describe '#destroy!' do
    it { is_expected.to respond_to(:destroy!) }
  end

  describe '#saved?' do
    subject(:record) { described_class.new(user_id: user_id, jti: jti) }

    it { is_expected.not_to be_saved }

    it 'is saved after save' do
      expect do
        record.save
      end.to change(record, :saved?).from(false).to true
    end
  end

  describe '#save' do
    subject(:record) { described_class.new(user_id: user_id, jti: jti) }

    it 'returns true' do
      expect(record.save).to be true
    end

    it 'is saved' do
      expect { record.save }.to change(record, :saved?).from(false).to true
    end

    it 'increments count' do
      expect { record.save }.to change(described_class, :count).by 1
    end

    it 'can be found' do
      record.save
      expect(described_class.find_by(user_id: user_id, jti: jti)).to eq record
    end
  end

  describe '#exp' do
    it 'defaults to #duration' do
      expect(record.exp).to be_within(1.second).of duration.from_now
    end

    it 'can be set with exp' do
      record = described_class.new(user_id: user_id, jti: jti)
      exp = 1.hour.from_now
      record.exp = exp
      expect(record.exp).to eq exp
    end

    context 'when record is saved' do
      before { record }

      it 'is the same as ttl' do
        Timecop.travel 5.minutes.from_now do
          expect(record.exp).to be_within(1.second).of duration.from_now - 5.minutes
        end
      end
    end
  end

  describe '#expire' do
    subject(:expire) { record.expire(dur) }

    let(:dur) { 1.hour }

    context 'when record is saved' do
      before { record }

      it { is_expected.to be true }

      it 'expires record' do
        expire
        expect(record.exp).to be_within(1.second).of 1.hour.from_now
      end
    end

    context 'when record is not saved' do
      subject(:record) { described_class.new(user_id: user_id, jti: jti) }

      it 'returns false' do
        expect(expire).to be false
      end
    end

    context 'when duration is a time' do
      let(:dur) { 1.hour.from_now }

      it { is_expected.to be true }

      it 'expires record' do
        expire
        expect(record.exp).to be_within(2.seconds).of 1.hour.from_now
      end
    end
  end

  describe '#pttl' do
    subject(:pttl) { record.pttl }

    context 'when record is saved' do
      before { record }

      it { is_expected.to be_a Integer }

      it 'is the same as ttl' do
        expected = Time.zone.now.floor + (pttl / 1_000).seconds
        expect(expected).to be_within(1.second).of record.exp
      end
    end

    context 'when record is not saved' do
      let(:record) { described_class.new(user_id: user_id, jti: jti) }

      it { is_expected.to be < 0 }
    end
  end
end
