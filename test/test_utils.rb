require 'helper'
require 'populate_me/utils'

describe PopulateMe::Utils do

  parallelize_me!

  let(:utils) { PopulateMe::Utils }

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
    describe 'with blank strings' do
      it 'is true' do
        ['',' '," \n \t"].each do |s|
          assert utils.blank?(s)
        end
      end
    end
    describe 'with nil' do
      it('is true') { assert utils.blank?(nil) }
    end
    describe 'with non-blank strings' do
      it 'is false' do
        ['a','abc', '  abc  '].each do |s|
          refute utils.blank?(s)
        end
      end
    end
    describe 'with integer' do
      it('is false') { refute utils.blank?(1234) }
    end
  end

  describe '#pluralize' do

    it "Just adds an 's' at the end" do
      assert_equal 'bags', utils.pluralize('bag')
      assert_equal 'days', utils.pluralize('day')
    end
    describe "The word ends with 'x'" do
      it "Adds 'es' instead" do
        assert_equal 'foxes', utils.pluralize('fox')
      end
    end
    describe "The word ends with a consonant and 'y'" do
      it "Replaces 'y' with 'ie'" do
        assert_equal 'copies', utils.pluralize('copy')
      end
    end

  end

  describe '#singularize' do

    it "Removes the trailing 's'" do
      assert_equal 'bag', utils.singularize('bags')
    end
    describe "The word ends with 'xes'" do
      it "Removes the 'e' as well" do
        assert_equal 'fox', utils.singularize('foxes')
      end
    end
    describe "The word ends with 'ies'" do
      it "Replaces 'ie' with 'y'" do
        assert_equal 'copy', utils.singularize('copies')
      end
    end

  end

  describe 'dasherize/undasherize class name' do

    let(:cases) {
      [
        ['Hello','hello'],
        ['HelloWorld','hello-world'],
        ['HTTPRequest','h-t-t-p-request'],
        ['RestAPI','rest-a-p-i'],
        ['AlteredSMTPAttachment','altered-s-m-t-p-attachment'],
        ['View360', 'view-360'],
        ['View360Degree', 'view-360-degree'],
        ['Degree360::View', 'degree-360--view'],
        ['RestAPI::Request::Post','rest-a-p-i--request--post'],
      ]
    }

    describe '#dasherize_class_name' do
      it "Translates correctly" do
        cases.each do |(classname,dashname)|
          assert_equal dashname, utils.dasherize_class_name(classname)
        end
      end
    end

    describe '#undasherize_class_name' do
      it "Translates correctly" do
        cases.each do |(classname,dashname)|
          assert_equal classname, utils.undasherize_class_name(dashname)
        end
      end
    end

  end

  describe '#resolve_class_name' do
    describe 'when the constant exists' do
      it 'Returns the constant' do
        [
          ['String',String],
          ['PopulateMe::Utils',PopulateMe::Utils],
        ].each do |(classname,constant)|
          assert_equal constant, utils.resolve_class_name(classname)
        end
      end
    end
    describe 'when the constant does not exist' do
      it 'Raise if the constant does not exist' do
        ['Strang','PopulateMe::Yootils','',nil].each do |classname|
          assert_raises(NameError) do
            utils.resolve_class_name(classname)
          end
        end
      end
    end
  end

  describe '#resolve_dasherized_class_name' do
    it 'Chains both methods for sugar' do
      assert_equal PopulateMe::Utils, utils.resolve_dasherized_class_name('populate-me--utils')
      assert_equal PopulateMe::Utils, utils.resolve_dasherized_class_name(:'populate-me--utils')
    end
  end

  describe '#guess_related_class_name' do
  
    # Used for many things but mainly relationship classes

    describe 'when it starts with a lowercase letter' do
      it 'Should guess a singular class_name in the context' do
        assert_equal 'PopulateMe::Utils::RelatedThing', utils.guess_related_class_name(PopulateMe::Utils, :related_things)
        assert_equal 'PopulateMe::Utils::RelatedThing', utils.guess_related_class_name(PopulateMe::Utils, :related_thing)
      end
    end
    describe 'when it starts with an uppercase letter' do
      it 'Should return the class_name as-is' do
        assert_equal 'Class::Given', utils.guess_related_class_name(PopulateMe::Utils, 'Class::Given')
      end
    end
    describe 'when it starts with ::' do
      it 'Should prepend the class_name whith the context' do
        assert_equal 'PopulateMe::Utils::RelatedThing', utils.guess_related_class_name(PopulateMe::Utils, '::RelatedThing')
      end
    end
  end

  describe '#get_value' do
    describe 'when arg is a simple object' do
      it 'Returns it as-is' do
        assert_equal 'Hello', utils.get_value('Hello')
      end
    end
    describe 'when arg is a proc' do
      it 'Returns after calling the proc' do
        assert_equal 'Hello', utils.get_value(proc{'Hello'})
      end
    end
    describe 'when arg is a symbol' do
      describe 'and a context is passed as a second argument' do
        it 'Sends the message to the context' do
          assert_equal 'Hello', utils.get_value(:capitalize,'hello')
        end
      end
      describe 'and no context is passed' do
        it 'Sends the message to Kernel' do
          assert_equal 'Kernel', utils.get_value(:to_s)
        end
      end
    end
  end

  describe '#deep_copy' do
    it 'Duplicates the nested objects' do
      original = {nested_hash: {one: 1}, nested_array: [1]}
      copy = utils.deep_copy(original)
      copy[:nested_hash][:one] = 2
      copy[:nested_array] << 2
      assert_equal({one: 1}, original[:nested_hash])
      assert_equal [1], original[:nested_array]
    end
  end

  describe '#ensure_key' do
    let(:arg) { {a: 3} }
    it 'Sets the key if it did not exist' do
      utils.ensure_key(arg,:b,4)
      assert_equal 4, arg[:b]
    end
    it 'Leaves the key untouched if it already existed' do
      utils.ensure_key(arg,:a,4)
      assert_equal 3, arg[:a]
    end
    it 'Returns the value of the key' do
      assert_equal 4, utils.ensure_key(arg,:b,4)
      assert_equal 3, utils.ensure_key(arg,:a,4)
    end
  end

  describe '#slugify' do

    # For making slug for a document
    # Possibly used instead of the id

    let(:arg) { "Así es la vida by Daniel Bär & Mickaël ? (100%)" }
    it 'Builds a string made of lowercase URL-friendly chars' do
      assert_equal 'asi-es-la-vida-by-daniel-bar-and-mickael-100%25', utils.slugify(arg)
    end
    describe 'when second argument is false' do
      it 'Does not force to lowercase' do
        assert_equal 'Asi-es-la-vida-by-Daniel-Bar-and-Mickael-100%25', utils.slugify(arg,false)
      end
    end
    describe 'when argument is nil' do
      let(:arg) { nil }
      it 'Does not break' do
        assert_equal '', utils.slugify(arg)
        assert_equal '', utils.slugify(arg,false)
      end
    end
  end

  describe '#label_for_field' do

    # Returns a friendly name for a field name

    it 'Returns an ideal title case version of the field name' do
      [
        ['hello', 'Hello'],
        ['hello-world_1234', 'Hello World 1234'],
        [:hello_world, 'Hello World'],
      ].each do |(arg,result)|
        assert_equal result, utils.label_for_field(arg)
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
      utils.each_stub(before) do |object,key_index,value|
        object[key_index] = value.to_s.downcase
      end
      assert_equal after, before
    end
    it 'Raises a TypeError if The object is not appropriate' do
      [nil,'yo',4].each do |obj|
        assert_raises(TypeError) do
          utils.each_stub(obj)
        end
      end
    end
  end

  describe '#automatic_typecast' do

    # Tries to do automatic typecasting of values
    # that are received as strings, so most likely
    # coming from a web form or from a CSV table.
    #
    # The purpose is to use it in combination with 
    # #each_stub when a form is received by the API.

    describe 'when a string' do
      it 'Knows how to convert recognizable datatypes' do
        [
          ['true',true],
          ['false',false],
          ['',nil],
          ['fack','fack']
        ].each do |(arg,result)|
          assert_equal result, utils.automatic_typecast(arg)
        end
      end
    end
    describe 'when not a string' do
      it 'Should leave it untouched' do
        [Time.now,1.0].each do |obj|
          assert_equal obj, utils.automatic_typecast(obj)
        end
      end
    end
  end

  describe '#generate_random_id' do
    it 'Has the correct format' do
      assert_match /[a-zA-Z0-9]{16}/, utils.generate_random_id
    end
    it 'Can have a specific length' do
      assert_match /[a-zA-Z0-9]{32}/, utils.generate_random_id(32)
    end
  end

  describe '#nl2br' do
    it 'Puts unclosed tags by default' do
      assert_equal '<br>Hello<br>world<br>', utils.nl2br("\nHello\nworld\n")
    end
    describe 'with 2nd argument' do
      it 'Replaces the tag' do
        assert_equal '<br/>Hello<br/>world<br/>', utils.nl2br("\nHello\nworld\n",'<br/>')
      end
    end
  end

  describe '#complete_link' do
    it 'Adds the external double slash when missing' do
      [
        ['www.populate-me.com','//www.populate-me.com'],
        ['populate-me.com','//populate-me.com'],
        ['please.populate-me.com','//please.populate-me.com'],
      ].each do |(arg,result)|
        assert_equal result, utils.complete_link(arg)
      end
    end
    it 'Does not alter the url when it does not need double slash' do
      [
        ['//www.populate-me.com','//www.populate-me.com'],
        ['://www.populate-me.com','://www.populate-me.com'],
        ['http://www.populate-me.com','http://www.populate-me.com'],
        ['ftp://www.populate-me.com','ftp://www.populate-me.com'],
        ['mailto:populate&#64;me.com','mailto:populate&#64;me.com'],
        ['',''],
        [' ',' '],
      ].each do |(arg,result)|
        assert_equal result, utils.complete_link(arg)
      end
    end
  end

  describe '#external_link?' do
    it 'Returns true when the link would need target=blank' do
      [
        ['http://populate-me.com', true],
        ['https://populate-me.com', true],
        ['ftp://populate-me.com', true],
        ['://populate-me.com', true],
        ['//populate-me.com', true],
        ['mailto:user@populate-me.com', false],
        ['mailto:user&#64;populate-me.com', false],
        ['/populate/me', false],
        ['populate-me.html', false],
      ].each do |(url,bool)|
        assert_equal bool, utils.external_link?(url)
      end
    end
  end

  describe '#automatic_html' do
    it 'Automates links and line breaks' do
      input = "Hello\nme@site.co.uk\nNot the begining me@site.co.uk\nme@site.co.uk not the end\nwww.site.co.uk\nVisit www.site.co.uk\nwww.site.co.uk rules\nhttp://www.site.co.uk\nVisit http://www.site.co.uk\nhttp://www.site.co.uk rules"
      output = "Hello<br><a href='mailto:me&#64;site.co.uk'>me&#64;site.co.uk</a><br>Not the begining <a href='mailto:me&#64;site.co.uk'>me&#64;site.co.uk</a><br><a href='mailto:me&#64;site.co.uk'>me&#64;site.co.uk</a> not the end<br><a href='//www.site.co.uk' target='_blank'>www.site.co.uk</a><br>Visit <a href='//www.site.co.uk' target='_blank'>www.site.co.uk</a><br><a href='//www.site.co.uk' target='_blank'>www.site.co.uk</a> rules<br><a href='http://www.site.co.uk' target='_blank'>http://www.site.co.uk</a><br>Visit <a href='http://www.site.co.uk' target='_blank'>http://www.site.co.uk</a><br><a href='http://www.site.co.uk' target='_blank'>http://www.site.co.uk</a> rules"
      assert_equal output, utils.automatic_html(input)
    end
  end

  describe '#truncate' do
    it 'Truncates to the right amount of letters' do
      assert_equal 'abc...', utils.truncate('abc defg hijklmnopqrstuvwxyz',3)
    end
    it 'Does not cut words' do
      assert_equal 'abcdefg...', utils.truncate('abcdefg hijklmnopqrstuvwxyz',3)
    end
    it 'Removes HTML tags' do
      assert_equal 'abcdefg...', utils.truncate('<br>abc<a href=#>def</a>g hijklmnopqrstuvwxyz',3)
    end
    it 'Does not print the ellipsis if the string is already short enough' do
      assert_equal 'abc def', utils.truncate('abc def',50)
    end
    describe 'with a 3rd argument' do 
      it 'Replaces the ellipsis' do
        assert_equal 'abc!', utils.truncate('abc defg hijklmnopqrstuvwxyz',3,'!')
        assert_equal 'abc', utils.truncate('abc defg hijklmnopqrstuvwxyz',3,'')
      end
    end
  end

  describe '#display_price' do
    it 'Turns a price number in cents/pence into a displayable one' do
      assert_equal '45.95', utils.display_price(4595)
    end
    it 'Removes cents if it is 00' do
      assert_equal '70', utils.display_price(7000)
    end
    it 'Adds comma delimiters on thousands' do
      assert_equal '12,345,678.90', utils.display_price(1234567890)
    end
    it 'Works with negative numbers' do
      assert_equal '-1,400', utils.display_price(-140000)
    end
    it 'Raises when argument is not int' do
      assert_raises(TypeError) do
        utils.display_price('abc')
      end
    end
  end

  describe '#parse_price' do
    it 'Parses a string and find the price in cents/pence' do
      assert_equal 4595, utils.parse_price('45.95')
    end
    it 'Works when you omit the cents/pence' do
      assert_equal 2800, utils.parse_price('28')
    end
    it 'Ignores visual help but works with negative prices' do
      assert_equal -1234567890, utils.parse_price('   £-12,345,678.90   ')
    end
    it 'Raises when argument is not string' do
      assert_raises(TypeError) do
        utils.parse_price(42)
      end
    end
  end

  describe '#branded_filename' do
    it 'Adds PopulateMe to the file name' do
      assert_equal "/path/to/PopulateMe-file.png", utils.branded_filename("/path/to/file.png")
    end
    it 'Works when there is just a file name' do
      assert_equal "PopulateMe-file.png", utils.branded_filename("file.png")
    end
    it 'Can change the brand' do
      assert_equal "/path/to/Brand-file.png", utils.branded_filename("/path/to/file.png",'Brand')
    end
  end

  describe '#filename_variation' do
    it 'Replaces the ext with variation name and new ext' do
      assert_equal "/path/to/file.thumb.gif", utils.filename_variation("/path/to/file.png", :thumb, :gif)
    end
    it 'Works when there is just a filename' do
      assert_equal "file.thumb.gif", utils.filename_variation("file.png", :thumb, :gif)
    end
    it "Works when there is no ext to start with" do
      assert_equal "/path/to/file.thumb.gif", utils.filename_variation("/path/to/file", :thumb, :gif)
    end
  end

  describe '#initial_request?' do
    let(:req) { 
      Rack::Request.new(
        Rack::MockRequest.env_for(
          '/path', 
          {'HTTP_REFERER'=>referer}
        )
      ) 
    }
    let(:referer) { nil }
    it 'Returns true' do
      assert utils.initial_request?(req)
    end
    describe 'Request comes from another domain' do
      let(:referer) { 'https://www.google.com/path' }
      it 'Returns true' do
        assert utils.initial_request?(req)
      end
    end
    describe 'Request comes from same domain' do
      let(:referer) { 'http://example.org' }
      it 'Returns false' do
        refute utils.initial_request?(req)
      end
    end
  end

end

