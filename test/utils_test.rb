require 'bacon'
require File.expand_path('../../lib/populate_me/utils', __FILE__)

DASH_CASES = [
  ['Hello','hello'],
  ['HelloWorld','hello-world'],
  ['HTTPRequest','h-t-t-p-request'],
  ['RestAPI','rest-a-p-i'],
  ['AlteredSMTPAttachment','altered-s-m-t-p-attachment']
]

describe 'PopulateMe::Utils' do
  describe '#dasherize_class_name' do
    it "Translates correctly" do
      DASH_CASES.each do |dash_case|
        PopulateMe::Utils.dasherize_class_name(dash_case[0]).should==dash_case[1]
      end
    end
  end
  describe '#undasherize_class_name' do
    it "Translates correctly" do
      DASH_CASES.each do |dash_case|
        PopulateMe::Utils.undasherize_class_name(dash_case[1]).should==dash_case[0]
      end
    end
  end
  describe '#blank?' do
    it 'Checks true correctly' do
      [nil,'',' '," \n \t"].each do |i|
        PopulateMe::Utils.blank?(i).should==true
      end
    end
    it 'Checks false correctly' do
      ['a','abc', '  abc  ', 1234].each do |i|
        PopulateMe::Utils.blank?(i).should==false
      end
    end
  end
end

