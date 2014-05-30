# encoding: utf-8

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
  describe '#slugify' do
    it 'Builds a string made of lowercase, dashes and URL-friendly chars' do
      PopulateMe::Utils.slugify("Así es la vida by Daniel Bär & Mickaël ? (100%)").should=='asi-es-la-vida-by-daniel-bar-and-mickael-100%25'
    end
    it 'Can keep uppercase letters when the second option(force_lower) is set to false' do
      PopulateMe::Utils.slugify("Así es la vida by Daniel Bär & Mickaël ? (100%)",false).should=='Asi-es-la-vida-by-Daniel-Bar-and-Mickael-100%25'
    end
    it 'Does not break when string is nil' do
      PopulateMe::Utils.slugify(nil).should==''
      PopulateMe::Utils.slugify(nil,false).should==''
    end
  end
end

