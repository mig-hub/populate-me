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
          _(utils.blank?(s)).must_equal(true)
        end
      end
    end
    describe 'with nil' do
      it('is true') { _(utils.blank?(nil)).must_equal(true) }
    end
    describe 'with non-blank strings' do
      it 'is false' do
        ['a','abc', '  abc  '].each do |s|
          _(utils.blank?(s)).must_equal(false)
        end
      end
    end
    describe 'with integer' do
      it('is false') { _(utils.blank?(1234)).must_equal(false) }
    end
  end

  describe '#pluralize' do

    it "Just adds an 's' at the end" do
      _(utils.pluralize('bag')).must_equal 'bags'
      _(utils.pluralize('day')).must_equal 'days'
    end
    describe "The word ends with 'x'" do
      it "Adds 'es' instead" do
        _(utils.pluralize('fox')).must_equal 'foxes'
      end
    end
    describe "The word ends with a consonant and 'y'" do
      it "Replaces 'y' with 'ie'" do
        _(utils.pluralize('copy')).must_equal 'copies'
      end
    end

  end

  describe '#singularize' do

    it "Removes the trailing 's'" do
      _(utils.singularize('bags')).must_equal 'bag'
    end
    describe "The word ends with 'xes'" do
      it "Removes the 'e' as well" do
        _(utils.singularize('foxes')).must_equal 'fox'
      end
    end
    describe "The word ends with 'ies'" do
      it "Replaces 'ie' with 'y'" do
        _(utils.singularize('copies')).must_equal 'copy'
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
        ['RestAPI::Request::Post','rest-a-p-i--request--post'],
      ]
    }

    describe '#dasherize_class_name' do
      it "Translates correctly" do
        cases.each do |(classname,dashname)|
          _(utils.dasherize_class_name(classname)).must_equal(dashname)
        end
      end
    end

    describe '#undasherize_class_name' do
      it "Translates correctly" do
        cases.each do |(classname,dashname)|
          _(utils.undasherize_class_name(dashname)).must_equal(classname)
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
          _(utils.resolve_class_name(classname)).must_equal(constant)
        end
      end
    end
    describe 'when the constant does not exist' do
      it 'Raise if the constant does not exist' do
        ['Strang','PopulateMe::Yootils','',nil].each do |classname|
          _ {utils.resolve_class_name(classname)}.must_raise(NameError)
        end
      end
    end
  end

  describe '#resolve_dasherized_class_name' do
    it 'Chains both methods for sugar' do
      _(utils.resolve_dasherized_class_name('populate-me--utils')).must_equal PopulateMe::Utils
      _(utils.resolve_dasherized_class_name(:'populate-me--utils')).must_equal PopulateMe::Utils
    end
  end

  describe '#guess_related_class_name' do
  
    # Used for many things but mainly relationship classes

    describe 'when it starts with a lowercase letter' do
      it 'Should guess a singular class_name in the context' do
        _(utils.guess_related_class_name(PopulateMe::Utils, :related_things)).must_equal('PopulateMe::Utils::RelatedThing')
        _(utils.guess_related_class_name(PopulateMe::Utils, :related_thing)).must_equal('PopulateMe::Utils::RelatedThing')
      end
    end
    describe 'when it starts with an uppercase letter' do
      it 'Should return the class_name as-is' do
        _(utils.guess_related_class_name(PopulateMe::Utils, 'Class::Given')).must_equal('Class::Given')
      end
    end
    describe 'when it starts with ::' do
      it 'Should prepend the class_name whith the context' do
        _(utils.guess_related_class_name(PopulateMe::Utils, '::RelatedThing')).must_equal('PopulateMe::Utils::RelatedThing')
      end
    end
  end

  describe '#get_value' do
    describe 'when arg is a simple object' do
      it 'Returns it as-is' do
        _(utils.get_value('Hello')).must_equal('Hello')
      end
    end
    describe 'when arg is a proc' do
      it 'Returns after calling the proc' do
        _(utils.get_value(proc{'Hello'})).must_equal('Hello')
      end
    end
    describe 'when arg is a symbol' do
      describe 'and a context is passed as a second argument' do
        it 'Sends the message to the context' do
          _(utils.get_value(:capitalize,'hello')).must_equal('Hello')
        end
      end
      describe 'and no context is passed' do
        it 'Sends the message to Kernel' do
          _(utils.get_value(:to_s)).must_equal('Kernel')
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
      _(original[:nested_hash]).must_equal({one: 1})
      _(original[:nested_array]).must_equal([1])
    end
  end

  describe '#ensure_key' do
    let(:arg) { {a: 3} }
    it 'Sets the key if it did not exist' do
      utils.ensure_key(arg,:b,4)
      _(arg[:b]).must_equal(4)
    end
    it 'Leaves the key untouched if it already existed' do
      utils.ensure_key(arg,:a,4)
      _(arg[:a]).must_equal(3)
    end
    it 'Returns the value of the key' do
      _(utils.ensure_key(arg,:b,4)).must_equal(4)
      _(utils.ensure_key(arg,:a,4)).must_equal(3)
    end
  end

  describe '#slugify' do

    # For making slug for a document
    # Possibly used instead of the id

    let(:arg) { "Así es la vida by Daniel Bär & Mickaël ? (100%)" }
    it 'Builds a string made of lowercase URL-friendly chars' do
      _(utils.slugify(arg)).must_equal('asi-es-la-vida-by-daniel-bar-and-mickael-100%25')
    end
    describe 'when second argument is false' do
      it 'Does not force to lowercase' do
        _(utils.slugify(arg,false)).must_equal('Asi-es-la-vida-by-Daniel-Bar-and-Mickael-100%25')
      end
    end
    describe 'when argument is nil' do
      let(:arg) { nil }
      it 'Does not break' do
        _(utils.slugify(arg)).must_equal('')
        _(utils.slugify(arg,false)).must_equal('')
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
        _(utils.label_for_field(arg)).must_equal(result)
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
      _(before).must_equal(after)
    end
    it 'Raises a TypeError if The object is not appropriate' do
      [nil,'yo',4].each do |obj|
        _ { utils.each_stub(obj) }.must_raise(TypeError)
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
          _(utils.automatic_typecast(arg)).must_equal(result)
        end
      end
    end
    describe 'when not a string' do
      it 'Should leave it untouched' do
        [Time.now,1.0].each do |obj|
          _(utils.automatic_typecast(obj)).must_equal(obj)
        end
      end
    end
  end

  describe '#generate_random_id' do
    it 'Has the correct format' do
      _(utils.generate_random_id).must_match(/[a-zA-Z0-9]{16}/)
    end
    it 'Can have a specific length' do
      _(utils.generate_random_id(32)).must_match (/[a-zA-Z0-9]{32}/)
    end
  end

  describe '#nl2br' do
    it 'Puts unclosed tags by default' do
      _(utils.nl2br("\nHello\nworld\n")).must_equal('<br>Hello<br>world<br>')
    end
    describe 'with 2nd argument' do
      it 'Replaces the tag' do
        _(utils.nl2br("\nHello\nworld\n",'<br/>')).must_equal('<br/>Hello<br/>world<br/>')
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
        _(utils.complete_link(arg)).must_equal(result)
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
        _(utils.complete_link(arg)).must_equal(result)
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
        _(utils.external_link?(url)).must_equal(bool)
      end
    end
  end

  describe '#automatic_html' do
    it 'Automates links and line breaks' do
      input = "Hello\nme@site.co.uk\nNot the begining me@site.co.uk\nme@site.co.uk not the end\nwww.site.co.uk\nVisit www.site.co.uk\nwww.site.co.uk rules\nhttp://www.site.co.uk\nVisit http://www.site.co.uk\nhttp://www.site.co.uk rules"
      output = "Hello<br><a href='mailto:me&#64;site.co.uk'>me&#64;site.co.uk</a><br>Not the begining <a href='mailto:me&#64;site.co.uk'>me&#64;site.co.uk</a><br><a href='mailto:me&#64;site.co.uk'>me&#64;site.co.uk</a> not the end<br><a href='//www.site.co.uk' target='_blank'>www.site.co.uk</a><br>Visit <a href='//www.site.co.uk' target='_blank'>www.site.co.uk</a><br><a href='//www.site.co.uk' target='_blank'>www.site.co.uk</a> rules<br><a href='http://www.site.co.uk' target='_blank'>http://www.site.co.uk</a><br>Visit <a href='http://www.site.co.uk' target='_blank'>http://www.site.co.uk</a><br><a href='http://www.site.co.uk' target='_blank'>http://www.site.co.uk</a> rules"
      _(utils.automatic_html(input)).must_equal(output)
    end
  end

  describe '#truncate' do
    it 'Truncates to the right amount of letters' do
      _(utils.truncate('abc defg hijklmnopqrstuvwxyz',3)).must_equal('abc...')
    end
    it 'Does not cut words' do
      _(utils.truncate('abcdefg hijklmnopqrstuvwxyz',3)).must_equal('abcdefg...')
    end
    it 'Removes HTML tags' do
      _(utils.truncate('<br>abc<a href=#>def</a>g hijklmnopqrstuvwxyz',3)).must_equal('abcdefg...')
    end
    it 'Does not print the ellipsis if the string is already short enough' do
      _(utils.truncate('abc def',50)).must_equal('abc def')
    end
    describe 'with a 3rd argument' do 
      it 'Replaces the ellipsis' do
        _(utils.truncate('abc defg hijklmnopqrstuvwxyz',3,'!')).must_equal('abc!')
        _(utils.truncate('abc defg hijklmnopqrstuvwxyz',3,'')).must_equal('abc')
      end
    end
  end

  describe '#display_price' do
    it 'Turns a price number in cents/pence into a displayable one' do
      _(utils.display_price(4595)).must_equal('45.95')
    end
    it 'Removes cents if it is 00' do
      _(utils.display_price(7000)).must_equal('70')
    end
    it 'Adds comma delimiters on thousands' do
      _(utils.display_price(1234567890)).must_equal('12,345,678.90')
    end
    it 'Works with negative numbers' do
      _(utils.display_price(-140000)).must_equal('-1,400')
    end
    it 'Raises when argument is not int' do
      _ {utils.display_price('abc')}.must_raise(TypeError)
    end
  end

  describe '#parse_price' do
    it 'Parses a string and find the price in cents/pence' do
      _(utils.parse_price('45.95')).must_equal(4595)
    end
    it 'Works when you omit the cents/pence' do
      _(utils.parse_price('28')).must_equal(2800)
    end
    it 'Ignores visual help but works with negative prices' do
      _(utils.parse_price('   £-12,345,678.90   ')).must_equal(-1234567890)
    end
    it 'Raises when argument is not string' do
      _ {utils.parse_price(42)}.must_raise(TypeError)
    end
  end

  describe '#branded_filename' do
    it 'Adds PopulateMe to the file name' do
      _(utils.branded_filename("/path/to/file.png")).must_equal("/path/to/PopulateMe-file.png")
    end
    it 'Works when there is just a file name' do
      _(utils.branded_filename("file.png")).must_equal("PopulateMe-file.png")
    end
    it 'Can change the brand' do
      _(utils.branded_filename("/path/to/file.png",'Brand')).must_equal("/path/to/Brand-file.png")
    end
  end

  describe '#filename_variation' do
    it 'Replaces the ext with variation name and new ext' do
      _(utils.filename_variation("/path/to/file.png", :thumb, :gif)).must_equal("/path/to/file.thumb.gif")
    end
    it 'Works when there is just a filename' do
      _(utils.filename_variation("file.png", :thumb, :gif)).must_equal("file.thumb.gif")
    end
    it "Works when there is no ext to start with" do
      _(utils.filename_variation("/path/to/file", :thumb, :gif)).must_equal("/path/to/file.thumb.gif")
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
      _(utils.initial_request?(req)).must_equal(true)
    end
    describe 'Request comes from another domain' do
      let(:referer) { 'https://www.google.com/path' }
      it 'Returns true' do
        _(utils.initial_request?(req)).must_equal(true)
      end
    end
    describe 'Request comes from same domain' do
      let(:referer) { 'http://example.org' }
      it 'Returns false' do
        _(utils.initial_request?(req)).must_equal(false)
      end
    end
  end

end

