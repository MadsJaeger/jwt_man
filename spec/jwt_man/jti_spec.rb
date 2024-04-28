require 'rails_helper'

RSpec.describe JwtMan::Jti do
  subject(:jti) { described_class.new(1) }

  it { is_expected.to be_a(String) }
  it { is_expected.to match(/\A[a-zA-Z0-9\-_]+\z/) }
  #
  # We want to test that two jtis are not the same when generated for the same user at the same time.
  # This is a very unlikely scenario, but we want to be sure.
  describe 'repeatability' do
    before :all do
      Timecop.freeze(Time.zone.now)

      @hex = JwtMan.config.jti_hex_length = 4

      @records = []
      threads = 5.times.map do
        Thread.new do
          20_000.times do
            @records.push described_class.new(1)
          end
        end
      end
      threads.each(&:join)

      @entries = @records.uniq.count
      @repeats = 100_000 - @entries
    end

    it 'for 100_000 entries' do
      expect(@records.size).to eq 100_000
    end

    it 'with a random hex length of 4' do
      expect(@hex).to eq 4
    end

    it 'the same user signing in at the same time will get less than 6 duplicate JTIs' do
      expect(@repeats).to be < 6
    end
  end
end
