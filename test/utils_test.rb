# encoding: utf-8

require 'bacon'
require File.expand_path('../../lib/populate_me/utils', __FILE__)


describe 'PopulateMe::Utils' do

  # This module contains helper methods used in many
  # places in the gem. Similar to Rack::Utils.
  #
  # Some methods could be implemented as extention methods
  # to basic ruby classes. If one day they are implemented as
  # extentions, I would rather keep them in Utils
  # and just proxy them.
  #
  # Some methods might be useful for the frontend.

  describe '#dasherize_class_name' do

    # Just makes a URL-friendly version of a Document/Model class name

    DASH_CASES = [
      ['Hello','hello'],
      ['HelloWorld','hello-world'],
      ['HTTPRequest','h-t-t-p-request'],
      ['RestAPI','rest-a-p-i'],
      ['AlteredSMTPAttachment','altered-s-m-t-p-attachment'],
      ['RestAPI::Request::Post','rest-a-p-i--request--post'],
    ]
    it "Translates correctly" do
      DASH_CASES.each do |dash_case|
        PopulateMe::Utils.dasherize_class_name(dash_case[0]).should==dash_case[1]
      end
    end
  end

  describe '#undasherize_class_name' do

    # Reverse of #dasherize_class_name
    # It takes the URL-friendly version
    # and returns the class name (string, not the constant)

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

    # For making slug for a document
    # Possibly used instead of the id

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

  describe '#each_stub' do
    
    # For iterating through end objects of a nested hash/array
    # It would be used for updating values, typecasting them...

    it 'Yields a block for every stub of a complex object and make changes possible' do
      before = {
        'name'=>"BoBBy",
        'numbers'=>['One','Two'],
        'meta'=>{'type'=>'Dev','tags'=>['Top','Bottom']}
      }
      after = {
        'name'=>"bobby",
        'numbers'=>['one','two'],
        'meta'=>{'type'=>'dev','tags'=>['top','bottom']}
      }
      PopulateMe::Utils.each_stub(before) do |object,key_index,value|
        object[key_index] = value.to_s.downcase
      end
      before.should==after
    end
  end

  describe '#automatic_typecast' do

    # Tries to do automatic typecasting of values
    # that are received as strings, so most likely
    # coming from a web form or from a CSV table.
    #
    # The purpose is to use it in combination with 
    # #each_stub when a form is received by the API.

    TYPECAST_CASES = [
      ['true',true],
      ['false',false],
      ['',nil]
    ]
    it 'Knows how to convert recognizable datatypes in strings' do
      TYPECAST_CASES.each do |c|
        PopulateMe::Utils.automatic_typecast(c[0]).should==c[1]
      end
    end
    it 'Should not typecast something which is not a string' do
      obj = Time.now
      PopulateMe::Utils.automatic_typecast(obj).should==obj
      PopulateMe::Utils.automatic_typecast(1.0).should==1.0
    end
  end

end

