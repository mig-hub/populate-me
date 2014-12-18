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

  describe '#resolve_class_name' do
    it 'Returns the constant if it exists' do
      PopulateMe::Utils.resolve_class_name('String').should==String
      PopulateMe::Utils.resolve_class_name('PopulateMe::Utils').should==PopulateMe::Utils
    end
    it 'Raise if the constant does not exist' do
      lambda{PopulateMe::Utils.resolve_class_name('Strang')}.should.raise(NameError)
      lambda{PopulateMe::Utils.resolve_class_name('PopulateMe::Yootils')}.should.raise(NameError)
      lambda{PopulateMe::Utils.resolve_class_name('')}.should.raise(TypeError)
      lambda{PopulateMe::Utils.resolve_class_name(nil)}.should.raise(TypeError)
    end
  end

  describe '#resolve_dasherized_class_name' do
    it 'Returns the constant if it exists' do
      PopulateMe::Utils.resolve_dasherized_class_name('string').should==String
      PopulateMe::Utils.resolve_dasherized_class_name('populate-me--utils').should==PopulateMe::Utils
    end
    it 'Raise if the constant does not exist' do
      lambda{PopulateMe::Utils.resolve_dasherized_class_name('strang')}.should.raise(NameError)
      lambda{PopulateMe::Utils.resolve_dasherized_class_name('populate-me--yootils')}.should.raise(NameError)
      lambda{PopulateMe::Utils.resolve_dasherized_class_name('')}.should.raise(TypeError)
      lambda{PopulateMe::Utils.resolve_dasherized_class_name(nil)}.should.raise(TypeError)
    end
  end

  describe '#guess_related_class_name' do
  
    it 'Should return the class_name as-is if it looks like a complete one' do
      PopulateMe::Utils.guess_related_class_name(PopulateMe::Utils, 'Class::Given').should=='Class::Given'
      PopulateMe::Utils.guess_related_class_name('PopulateMe::Utils', :'Class::Given').should=='Class::Given'
    end

    it 'Should prepend the class_name whith the context if class_name starts with ::' do
      PopulateMe::Utils.guess_related_class_name(PopulateMe::Utils, '::RelatedThing').should=='PopulateMe::Utils::RelatedThing'
      PopulateMe::Utils.guess_related_class_name('PopulateMe::Utils', :'::RelatedThing').should=='PopulateMe::Utils::RelatedThing'
    end

    it 'Should guess a singular class_name in the context when the class_name starts with a lowercase letter' do
      PopulateMe::Utils.guess_related_class_name(PopulateMe::Utils, :related_things).should=='PopulateMe::Utils::RelatedThing'
      PopulateMe::Utils.guess_related_class_name('PopulateMe::Utils', 'related_things').should=='PopulateMe::Utils::RelatedThing'
      PopulateMe::Utils.guess_related_class_name(PopulateMe::Utils, :related_thing).should=='PopulateMe::Utils::RelatedThing'
      PopulateMe::Utils.guess_related_class_name('PopulateMe::Utils', 'related_thing').should=='PopulateMe::Utils::RelatedThing'
    end

  end

  describe '#get_value' do

    it 'Can get the value of anything it can' do
      PopulateMe::Utils.get_value('Hello').should=='Hello'
      PopulateMe::Utils.get_value(proc{'Hello'}).should=='Hello'
      PopulateMe::Utils.get_value(:capitalize,'hello').should=='Hello'
    end

  end

  describe '#ensure_key' do

    it 'Sets the key if the key did not exist' do
      h = {a: 3}
      PopulateMe::Utils.ensure_key(h,:a,4).should==3
      h[:a].should==3
      PopulateMe::Utils.ensure_key(h,:b,4).should==4
      h[:b].should==4
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

  describe '#label_for_field' do

    # Returns a friendly name for a field name

    LABEL_CASES = [
      ['hello', 'Hello'],
      ['hello-world_1234', 'Hello World 1234'],
      [:hello_world, 'Hello World']
    ]

    it 'Returns an ideal title case version of the field name' do
      LABEL_CASES.each do |label_case|
        PopulateMe::Utils.label_for_field(label_case[0]).should==label_case[1]
      end
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

    it 'Raises a TypeError if The object is not appropriate' do
      lambda{ PopulateMe::Utils.each_stub(nil) }.should.raise(TypeError)
      lambda{ PopulateMe::Utils.each_stub('yo') }.should.raise(TypeError)
      lambda{ PopulateMe::Utils.each_stub(4) }.should.raise(TypeError)
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
      ['',nil],
      ['fack','fack']
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

  describe '#generate_random_id' do
    it 'Has the correct format' do
      PopulateMe::Utils.generate_random_id.should =~ /[a-zA-Z0-9]{16}/
      PopulateMe::Utils.generate_random_id(32).should =~ /[a-zA-Z0-9]{32}/
    end
  end

  describe '#nl2br' do
    it 'Puts unclosed tags by default' do
      PopulateMe::Utils.nl2br("Hello\nworld").should=='Hello<br>world'
      PopulateMe::Utils.nl2br("\nHello\nworld\n").should=='<br>Hello<br>world<br>'
    end
    it 'Can put closed tags instead' do
      # Only if implementation is short enough
      PopulateMe::Utils.nl2br("Hello\nworld",'<br/>').should=='Hello<br/>world'
      PopulateMe::Utils.nl2br("\nHello\nworld\n",'<br/>').should=='<br/>Hello<br/>world<br/>'
    end
  end

  describe '#complete_link' do

    it 'Adds the external double slash when missing' do
      cases = [
        ['www.populate-me.com','//www.populate-me.com'],
        ['populate-me.com','//populate-me.com'],
        ['please.populate-me.com','//please.populate-me.com'],
        ['//www.populate-me.com','//www.populate-me.com'],
        ['://www.populate-me.com','://www.populate-me.com'],
        ['http://www.populate-me.com','http://www.populate-me.com'],
        ['ftp://www.populate-me.com','ftp://www.populate-me.com'],
        ['mailto:populate&#64;me.com','mailto:populate&#64;me.com']
      ]
      cases.each do |c|
        PopulateMe::Utils.complete_link(c[0]).should==c[1]
      end
    end

  end

  describe '#external_link?' do

    it 'Returns true when the link would need target blank' do
      cases = [
        ['http://populate-me.com', true],
        ['https://populate-me.com', true],
        ['ftp://populate-me.com', true],
        ['://populate-me.com', true],
        ['//populate-me.com', true],
        ['mailto:user@populate-me.com', false],
        ['mailto:user&#64;populate-me.com', false],
        ['/populate/me', false],
        ['populate-me.html', false],
      ]
      cases.each do |c|
        PopulateMe::Utils.external_link?(c[0]).should==c[1]
      end
    end

  end

  describe '#automatic_html' do
    it 'Works properly' do
      input = "Hello\nme@site.co.uk\nNot the begining me@site.co.uk\nme@site.co.uk not the end\nwww.site.co.uk\nVisit www.site.co.uk\nwww.site.co.uk rules\nhttp://www.site.co.uk\nVisit http://www.site.co.uk\nhttp://www.site.co.uk rules"
      output = "Hello<br><a href='mailto:me&#64;site.co.uk'>me&#64;site.co.uk</a><br>Not the begining <a href='mailto:me&#64;site.co.uk'>me&#64;site.co.uk</a><br><a href='mailto:me&#64;site.co.uk'>me&#64;site.co.uk</a> not the end<br><a href='//www.site.co.uk' target='_blank'>www.site.co.uk</a><br>Visit <a href='//www.site.co.uk' target='_blank'>www.site.co.uk</a><br><a href='//www.site.co.uk' target='_blank'>www.site.co.uk</a> rules<br><a href='http://www.site.co.uk' target='_blank'>http://www.site.co.uk</a><br>Visit <a href='http://www.site.co.uk' target='_blank'>http://www.site.co.uk</a><br><a href='http://www.site.co.uk' target='_blank'>http://www.site.co.uk</a> rules"
      PopulateMe::Utils.automatic_html(input).should==output
    end
  end

  describe '#truncate' do
    it 'Limit to the right amount of letters' do
      PopulateMe::Utils.truncate('abc defg hijklmnopqrstuvwxyz',3).should=='abc...'
    end
    it 'Does not cut words' do
      PopulateMe::Utils.truncate('abcdefg hijklmnopqrstuvwxyz',3).should=='abcdefg...'
    end
    it 'Removes HTML tags' do
      PopulateMe::Utils.truncate('<br>abc<a href=#>def</a>g hijklmnopqrstuvwxyz',3).should=='abcdefg...'
    end
    it 'Can replace the ellipsis by anything' do
      PopulateMe::Utils.truncate('abc defg hijklmnopqrstuvwxyz',3,'!').should=='abc!'
      PopulateMe::Utils.truncate('abc defg hijklmnopqrstuvwxyz',3,'').should=='abc'
    end
    it 'Does not print the ellipsis if the string is already short enough' do
      PopulateMe::Utils.truncate('abc def',50).should=='abc def'
    end
  end

  describe '#display_price' do
    it 'Turns a price number in cents/pence into a displayable one' do
      PopulateMe::Utils.display_price(4595).should=='45.95'
    end
    it 'Removes cents if it is 00' do
      PopulateMe::Utils.display_price(7000).should=='70'
    end
    it 'Adds comma delimiters on thousands' do
      PopulateMe::Utils.display_price(1234567890).should=='12,345,678.90'
    end
    it 'Works with negative numbers' do
      PopulateMe::Utils.display_price(-140000).should=='-1,400'
    end
    it 'Raises when argument is not int' do
      lambda{PopulateMe::Utils.display_price('abc')}.should.raise(TypeError)
    end
  end

  describe '#parse_price' do
    it 'Parses a string and find the price in cents/pence' do
      PopulateMe::Utils.parse_price('45.95').should==4595
    end
    it 'Works when you omit the cents/pence' do
      PopulateMe::Utils.parse_price('28').should==2800
    end
    it 'Ignores visual help but works with negative prices' do
      PopulateMe::Utils.parse_price('   £-12,345,678.90   ').should==-1234567890
    end
    it 'Raises when argument is not string' do
      lambda{PopulateMe::Utils.parse_price(42)}.should.raise(TypeError)
    end
  end

end

