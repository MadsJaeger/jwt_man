require 'rails_helper'

RSpec.describe JWT::UserNotFound do
  it 'inherits from JWT::DecodeError' do
    expect(described_class.superclass).to eq JWT::DecodeError
  end

  it 'can be raised' do
    expect { raise described_class }.to raise_error described_class
  end
end
