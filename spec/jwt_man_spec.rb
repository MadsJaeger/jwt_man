require 'rails_helper'

RSpec.describe JwtMan do
  it 'has a version number' do
    expect(JwtMan::VERSION).to match(/\d+\.\d+\.\d+/)
  end

  describe 'Configuration' do
    describe '.config' do
      it 'returns JwtMan::Config' do
        expect(described_class.config).to be JwtMan::Config
      end

      it 'responds to duration' do
        expect(described_class.config).to respond_to :duration
      end
    end

    describe '.configure' do
      before do
        described_class.configure do |config|
          config.duration  = 1.hour
          config.algorithm = 'HS512'
          config.secret    = 'my secret'
        end
      end

      it 'yields a JwtMan::Config instance' do
        expect { |b| described_class.configure(&b) }.to yield_with_args(JwtMan::Config)
      end

      it 'sets the duration' do
        expect(described_class.config.duration).to eq 1.hour
      end

      it 'sets the algorithm' do
        expect(JwtMan::Config.algorithm).to eq 'HS512'
      end

      it 'sets the secret' do
        expect(JwtMan::Config.secret).to eq 'my secret'
      end
    end
  end
end
