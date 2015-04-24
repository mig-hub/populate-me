require 'populate_me/version'

RSpec.describe 'Version' do
  subject { PopulateMe::VERSION }
  it { is_expected.to match(/\d+\.\d+\.\d+/) }
end

