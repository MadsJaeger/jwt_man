require 'rails_helper'

RSpec.describe JwtMan::Blacklist do
  include_examples 'JTI List', JwtMan::Config.duration
end
