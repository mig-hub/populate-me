require 'populate_me/utils'

RSpec.describe PopulateMe::Utils do
  subject(:utils) { described_class }

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
    context 'with blank strings' do
      it 'is true' do
        ['',' '," \n \t"].each do |s|
          expect(utils.blank?(s)).to eq(true)
        end
      end
    end
    context 'with nil' do
      it('is true') { expect(utils.blank?(nil)).to eq(true) }
    end
    context 'with non-blank strings' do
      it 'is false' do
        ['a','abc', '  abc  '].each do |s|
          expect(utils.blank?(s)).to eq(false)
        end
      end
    end
    context 'with integer' do
      it('is false') { expect(utils.blank?(1234)).to eq(false) }
    end
  end

  describe '#pluralize' do

    it "Just adds an 's' at the end" do
      expect(utils.pluralize('bag')).to eq 'bags'
      expect(utils.pluralize('day')).to eq 'days'
    end
    context "The word ends with 'x'" do
      it "Adds 'es' instead" do
        expect(utils.pluralize('fox')).to eq 'foxes'
      end
    end
    context "The word ends with a consonant and 'y'" do
      it "Replaces 'y' with 'ie'" do
        expect(utils.pluralize('copy')).to eq 'copies'
      end
    end

  end

  describe '#singularize' do

    it "Removes the trailing 's'" do
      expect(utils.singularize('bags')).to eq 'bag'
    end
    context "The word ends with 'xes'" do
      it "Removes the 'e' as well" do
        expect(utils.singularize('foxes')).to eq 'fox'
      end
    end
    context "The word ends with 'ies'" do
      it "Replaces 'ie' with 'y'" do
        expect(utils.singularize('copies')).to eq 'copy'
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
          expect(utils.dasherize_class_name(classname)).to eq(dashname)
        end
      end
    end

    describe '#undasherize_class_name' do
      it "Translates correctly" do
        cases.each do |(classname,dashname)|
          expect(utils.undasherize_class_name(dashname)).to eq(classname)
        end
      end
    end

  end

  describe '#resolve_class_name' do
    context 'when the constant exists' do
      it 'Returns the constant' do
        [
          ['String',String],
          ['PopulateMe::Utils',PopulateMe::Utils],
        ].each do |(classname,constant)|
          expect(utils.resolve_class_name(classname)).to eq(constant)
        end
      end
    end
    context 'when the constant does not exist' do
      it 'Raise if the constant does not exist' do
        ['Strang','PopulateMe::Yootils','',nil].each do |classname|
          expect {utils.resolve_class_name(classname)}.to raise_error(NameError)
        end
      end
    end
  end

  describe '#resolve_dasherized_class_name' do
    it 'Chains both methods for sugar' do
      s = 'populate-me--utils'
      expect(s).to receive(:to_s)
      expect(utils).to receive(:undasherize_class_name)
      expect(utils).to receive(:resolve_class_name)
      utils.resolve_dasherized_class_name(s)
    end
  end

  describe '#guess_related_class_name' do
  
    # Used for many things but mainly relationship classes

    context 'when it starts with a lowercase letter' do
      it 'Should guess a singular class_name in the context' do
        allow(utils).to receive(:undasherize_class_name).with('related-thing').and_return('RelatedThing')
        expect(utils.guess_related_class_name(PopulateMe::Utils, :related_things)).to eq('PopulateMe::Utils::RelatedThing')
        expect(utils.guess_related_class_name(PopulateMe::Utils, :related_thing)).to eq('PopulateMe::Utils::RelatedThing')
      end
    end
    context 'when it starts with an uppercase letter' do
      it 'Should return the class_name as-is' do
        expect(utils.guess_related_class_name(PopulateMe::Utils, 'Class::Given')).to eq('Class::Given')
      end
    end
    context 'when it starts with ::' do
      it 'Should prepend the class_name whith the context' do
        expect(utils.guess_related_class_name(PopulateMe::Utils, '::RelatedThing')).to eq('PopulateMe::Utils::RelatedThing')
      end
    end
  end

  describe '#get_value' do
    context 'when arg is a simple object' do
      it 'Returns it as-is' do
        expect(utils.get_value('Hello')).to eq('Hello')
      end
    end
    context 'when arg is a proc' do
      it 'Returns after calling the proc' do
        expect(utils.get_value(proc{'Hello'})).to eq('Hello')
      end
    end
    context 'when arg is a symbol' do
      context 'and a context is passed as a second argument' do
        it 'Sends the message to the context' do
          expect(utils.get_value(:capitalize,'hello')).to eq('Hello')
        end
      end
      context 'and no context is passed' do
        it 'Sends the message to Kernel' do
          expect(utils.get_value(:to_s)).to eq('Kernel')
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
      expect(original[:nested_hash]).to eq({one: 1})
      expect(original[:nested_array]).to eq([1])
    end
  end

  describe '#ensure_key' do
    let(:arg) { {a: 3} }
    it 'Sets the key if it did not exist' do
      utils.ensure_key(arg,:b,4)
      expect(arg[:b]).to eq(4)
    end
    it 'Leaves the key untouched if it already existed' do
      utils.ensure_key(arg,:a,4)
      expect(arg[:a]).to eq(3)
    end
    it 'Returns the value of the key' do
      expect(utils.ensure_key(arg,:b,4)).to eq(4)
      expect(utils.ensure_key(arg,:a,4)).to eq(3)
    end
  end

  describe '#slugify' do

    # For making slug for a document
    # Possibly used instead of the id

    let(:arg) { "Así es la vida by Daniel Bär & Mickaël ? (100%)" }
    it 'Builds a string made of lowercase URL-friendly chars' do
      expect(utils.slugify(arg)).to eq('asi-es-la-vida-by-daniel-bar-and-mickael-100%25')
    end
    context 'when second argument is false' do
      it 'Does not force to lowercase' do
        expect(utils.slugify(arg,false)).to eq('Asi-es-la-vida-by-Daniel-Bar-and-Mickael-100%25')
      end
    end
    context 'when argument is nil' do
      let(:arg) { nil }
      it 'Does not break' do
        expect(utils.slugify(arg)).to eq('')
        expect(utils.slugify(arg,false)).to eq('')
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
        expect(utils.label_for_field(arg)).to eq(result)
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
      expect(before).to eq(after)
    end
    it 'Raises a TypeError if The object is not appropriate' do
      [nil,'yo',4].each do |obj|
        expect { utils.each_stub(obj) }.to raise_error(TypeError)
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

    context 'when a string' do
      it 'Knows how to convert recognizable datatypes' do
        [
          ['true',true],
          ['false',false],
          ['',nil],
          ['fack','fack']
        ].each do |(arg,result)|
          expect(utils.automatic_typecast(arg)).to eq(result)
        end
      end
    end
    context 'when not a string' do
      it 'Should leave it untouched' do
        [Time.now,1.0].each do |obj|
          expect(utils.automatic_typecast(obj)).to eq(obj)
        end
      end
    end
  end

  describe '#generate_random_id' do
    it 'Has the correct format' do
      expect(utils.generate_random_id).to match(/[a-zA-Z0-9]{16}/)
    end
    it 'Can have a specific length' do
      expect(utils.generate_random_id(32)).to match (/[a-zA-Z0-9]{32}/)
    end
  end

  describe '#nl2br' do
    it 'Puts unclosed tags by default' do
      expect(utils.nl2br("\nHello\nworld\n")).to eq('<br>Hello<br>world<br>')
    end
    context 'with 2nd argument' do
      it 'Replaces the tag' do
        expect(utils.nl2br("\nHello\nworld\n",'<br/>')).to eq('<br/>Hello<br/>world<br/>')
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
        expect(utils.complete_link(arg)).to eq(result)
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
        expect(utils.complete_link(arg)).to eq(result)
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
        expect(utils.external_link?(url)).to eq(bool)
      end
    end
  end

  describe '#automatic_html' do
    it 'Automates links and line breaks' do
      input = "Hello\nme@site.co.uk\nNot the begining me@site.co.uk\nme@site.co.uk not the end\nwww.site.co.uk\nVisit www.site.co.uk\nwww.site.co.uk rules\nhttp://www.site.co.uk\nVisit http://www.site.co.uk\nhttp://www.site.co.uk rules"
      output = "Hello<br><a href='mailto:me&#64;site.co.uk'>me&#64;site.co.uk</a><br>Not the begining <a href='mailto:me&#64;site.co.uk'>me&#64;site.co.uk</a><br><a href='mailto:me&#64;site.co.uk'>me&#64;site.co.uk</a> not the end<br><a href='//www.site.co.uk' target='_blank'>www.site.co.uk</a><br>Visit <a href='//www.site.co.uk' target='_blank'>www.site.co.uk</a><br><a href='//www.site.co.uk' target='_blank'>www.site.co.uk</a> rules<br><a href='http://www.site.co.uk' target='_blank'>http://www.site.co.uk</a><br>Visit <a href='http://www.site.co.uk' target='_blank'>http://www.site.co.uk</a><br><a href='http://www.site.co.uk' target='_blank'>http://www.site.co.uk</a> rules"
      expect(utils.automatic_html(input)).to eq(output)
    end
  end

  describe '#truncate' do
    it 'Truncates to the right amount of letters' do
      expect(utils.truncate('abc defg hijklmnopqrstuvwxyz',3)).to eq('abc...')
    end
    it 'Does not cut words' do
      expect(utils.truncate('abcdefg hijklmnopqrstuvwxyz',3)).to eq('abcdefg...')
    end
    it 'Removes HTML tags' do
      expect(utils.truncate('<br>abc<a href=#>def</a>g hijklmnopqrstuvwxyz',3)).to eq('abcdefg...')
    end
    it 'Does not print the ellipsis if the string is already short enough' do
      expect(utils.truncate('abc def',50)).to eq('abc def')
    end
    context 'with a 3rd argument' do 
      it 'Replaces the ellipsis' do
        expect(utils.truncate('abc defg hijklmnopqrstuvwxyz',3,'!')).to eq('abc!')
        expect(utils.truncate('abc defg hijklmnopqrstuvwxyz',3,'')).to eq('abc')
      end
    end
  end

  describe '#display_price' do
    it 'Turns a price number in cents/pence into a displayable one' do
      expect(utils.display_price(4595)).to eq('45.95')
    end
    it 'Removes cents if it is 00' do
      expect(utils.display_price(7000)).to eq('70')
    end
    it 'Adds comma delimiters on thousands' do
      expect(utils.display_price(1234567890)).to eq('12,345,678.90')
    end
    it 'Works with negative numbers' do
      expect(utils.display_price(-140000)).to eq('-1,400')
    end
    it 'Raises when argument is not int' do
      expect {utils.display_price('abc')}.to raise_error(TypeError)
    end
  end

  describe '#parse_price' do
    it 'Parses a string and find the price in cents/pence' do
      expect(utils.parse_price('45.95')).to eq(4595)
    end
    it 'Works when you omit the cents/pence' do
      expect(utils.parse_price('28')).to eq(2800)
    end
    it 'Ignores visual help but works with negative prices' do
      expect(utils.parse_price('   £-12,345,678.90   ')).to eq(-1234567890)
    end
    it 'Raises when argument is not string' do
      expect {utils.parse_price(42)}.to raise_error(TypeError)
    end
  end

  describe '#branded_filename' do
    it 'Adds PopulateMe to the file name' do
      expect(utils.branded_filename("/path/to/file.png")).to eq("/path/to/PopulateMe-file.png")
    end
    it 'Works when there is just a file name' do
      expect(utils.branded_filename("file.png")).to eq("PopulateMe-file.png")
    end
    it 'Can change the brand' do
      expect(utils.branded_filename("/path/to/file.png",'Brand')).to eq("/path/to/Brand-file.png")
    end
  end

  describe '#filename_variation' do
    it 'Replaces the ext with variation name and new ext' do
      expect(utils.filename_variation("/path/to/file.png", :thumb, :gif)).to eq("/path/to/file.thumb.gif")
    end
    it 'Works when there is just a filename' do
      expect(utils.filename_variation("file.png", :thumb, :gif)).to eq("file.thumb.gif")
    end
    it "Works when there is no ext to start with" do
      expect(utils.filename_variation("/path/to/file", :thumb, :gif)).to eq("/path/to/file.thumb.gif")
    end
  end

end

