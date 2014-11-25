require 'bacon'
require File.expand_path('../../lib/populate_me/version', __FILE__)

describe 'PopulateMe::VERSION' do
  it 'Is formated correctly' do
    PopulateMe::VERSION.split('.').size.should==3
  end
end

