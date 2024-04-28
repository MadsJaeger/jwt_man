require 'rails_helper'

RSpec.describe JwtMan::CollectionDuck do
  subject(:collection) do
    described_class.new 5.times.map { double(destroy: true) }
  end

  it { is_expected.to be_a(Array) }
  it { is_expected.to respond_to(:destroy_all) }
  it { is_expected.to respond_to(:destroy_all!) }
  it { is_expected.to respond_to(:delete_all) }
end
