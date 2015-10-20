require 'helper'
require 'populate_me/version'

describe 'Version' do
  parallelize_me!
  subject { PopulateMe::VERSION }
  it 'Is well formed' do 
    subject.must_match(/\d+\.\d+\.\d+/)
  end
end

