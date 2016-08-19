require 'helper'
require 'populate_me/version'

describe 'Version' do
  parallelize_me!
  subject { PopulateMe::VERSION }
  it 'Is well formed' do 
    assert_match /\d+\.\d+\.\d+/, subject
  end
end

