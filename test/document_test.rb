require 'bacon'
$:.unshift File.expand_path('../../lib', __FILE__)
require 'populate_me/document'

describe 'PopulateMe::Document' do

  # PopulateMe::Document is the base for any document
  # the Backend is supposed to deal with.
  #
  # Any module for a specific ORM or ODM should include
  # this module first.
  # It contains what is not specific to a particular kind
  # of database and it provides defaults.
  #
  # It can be used on its own but it keeps everything
  # in memory. Which means it is only for tests and conceptual
  # understanding.

  describe 'Descriptive methods' do

    module Catalogue; end
    module Catalogue::Chapter; end
    class Catalogue::Chapter::AttachedFile
      include PopulateMe::Document
      attr_accessor :name, :size
      label :name
    end

    it 'Has a friendly name on Class::to_s' do
      # Simple plural (override if exception)
      Catalogue::Chapter::AttachedFile.name.should=='Catalogue::Chapter::AttachedFile'
      Catalogue::Chapter::AttachedFile.to_s.should=='Catalogue Chapter Attached File'
    end

    it 'Has a plural version which only adds a `s` by default' do
      Catalogue::Chapter::AttachedFile.to_s_plural.should=='Catalogue Chapter Attached Files'
    end

    it 'Uses the label variable as a description for instances when there is one' do
      file = Catalogue::Chapter::AttachedFile.new
      file.name = 'file.pdf'
      file.size = '300KB'
      file.to_s.should=='file.pdf'
    end

    it 'Uses a default name instead when the label field is blank or not set' do
      file = Catalogue::Chapter::AttachedFile.new
      file.to_s.should==file.inspect
      Catalogue::Chapter::AttachedFile.label_field = nil
      file.to_s.should==file.inspect
    end

  end

  class Couch
    include PopulateMe::Document
    slot :colour, required: true
    slot :capacity, type: :integer
    slot :price, type: :price, required: true
    slot :available, type: :boolean
  end

  describe 'Attributes' do

    it 'Can declare attributes and options about them in one go' do
      Couch.slots.size.should==4
      Couch.slots.keys.should==[:colour, :capacity, :price, :available]
      Couch.slots[:available][:type].should==:boolean
      Couch.slots[:price][:required].should==true
      couch = Couch.new
      couch.price = 300
      couch.price.should==300
    end

    it 'Uses the first slot as label when label field is not specified' do
      couch = Couch.new
      couch.colour = 'White'
      couch.to_s.should=='White'
      Couch.label_field = :capacity
      couch.to_s.should==couch.inspect
    end

  end

  class Egg
    include PopulateMe::Document
    attr_accessor :size, :taste, :_hidden
  end

  describe 'Initializing and setting' do

    it 'Can set variables with a hash' do
      obj = Egg.new
      obj.set size: 1, taste: 'good'
      obj.size.should==1
      obj.taste.should=='good'
    end

    it 'Can set variables with string keys' do
      obj = Egg.new
      obj.set 'size'=>4, 'taste'=>'good'
      obj.size.should==4
      obj.taste.should=='good'
    end

    it 'Cannot set variables without an accessor' do
      obj = Egg.new
      lambda{ obj.set color: 'blue' }.should.raise(NoMethodError)
    end

    it 'Can set values when initializing' do
      obj = Egg.new size: 1, taste: 'good'
      obj.size.should==1
      obj.taste.should=='good'
      obj.new?.should==true
    end

    it 'Can set _is_new when initializing' do
      obj = Egg.new size: 1, taste: 'good', _is_new: false
      obj.size.should==1
      obj.taste.should=='good'
      obj.new?.should==false
    end

    it 'Can return a list of persistent instance variables' do
      # Only keys which do not start with an underscore are persistent
      obj = Egg.new size: 3, _hidden: 'secret'
      obj.size.should==3
      obj.taste.should==nil
      obj._hidden.should=='secret'
      obj.persistent_instance_variables.should==[:@size]
    end

    it 'Turns into a hash with string keys' do
      obj = Egg.new
      obj.to_h.should=={'_class'=>'Egg'}
      obj.set size: 1, taste: 'good', _hidden: 'secret'
      obj._hidden.should=='secret'
      obj.to_h.should=={'size'=>1,'taste'=>'good','_class'=>'Egg'}
      obj.to_h.should==obj.to_hash
    end

  end

  describe 'Callbacks' do

    class Hamburger
      include PopulateMe::Document
      attr_accessor :taste

      register_callback :layers, :bread
      register_callback :layers, :cheese
      register_callback :layers do
        self.taste
      end

      register_callback :after_cook, :add_salad
      register_callback :after_cook do
        taste << ' with more cheese'
      end
      def add_salad
        taste << ' with salad'
      end

      register_callback :after_eat do
        taste << ' stomach'
      end
      register_callback :after_eat, prepend: true do
        taste << ' my'
      end
      register_callback :after_eat, :prepend_for, prepend: true
      def prepend_for
        taste << ' for'
      end

      before :digest do
        taste << ' taste'
      end
      before :digest, :add_dot
      before :digest, prepend: true do
        taste << ' the'
      end
      before :digest, :prepend_was, prepend: true
      after :digest do
        taste << ' taste'
      end
      after :digest, :add_dot
      after :digest, prepend: true do
        taste << ' the'
      end
      after :digest, :prepend_was, prepend: true
      def add_dot; taste << '.'; end
      def prepend_was; taste << ' was'; end

      before :argument do |name|
        taste << " #{name}"
      end
      after :argument, :after_with_arg
      def after_with_arg(name)
        taste << " #{name}"
      end
    end

    it 'Registers callbacks as symbols or blocks' do
      Hamburger.callbacks[:layers].size.should==3
      Hamburger.callbacks[:layers][0].should==:bread
      Hamburger.callbacks[:layers][1].should==:cheese
      h = Hamburger.new taste: 'good'
      h.instance_eval(&Hamburger.callbacks[:layers][2]).should=='good'
    end

    it 'Executes symbol or block callbacks' do
      h = Hamburger.new taste: 'good'
      h.exec_callback('after_cook').taste.should=='good with salad with more cheese'
    end

    it 'Does not raise if executing a callback which does not exist' do
      h = Hamburger.new taste: 'good'
      h.exec_callback(:after_burn).taste.should=='good'
    end

    it 'Has an option to prepend when registering callbacks' do
      h = Hamburger.new taste: 'good'
      h.exec_callback(:after_eat).taste.should=='good for my stomach'
    end

    it 'Has callback shortcuts for before and after' do
      h = Hamburger.new taste: 'good'
      h.exec_callback(:before_digest).taste.should=='good was the taste.'
      h.taste = 'good'
      h.exec_callback(:after_digest).taste.should=='good was the taste.'
    end

    it 'Optionally takes the callback name as an argument' do
      h = Hamburger.new taste: 'good'
      h.exec_callback(:before_argument).taste.should=='good before_argument'
      h.exec_callback(:after_argument).taste.should=='good before_argument after_argument'
    end

  end

  class User
    include PopulateMe::Document
    attr_accessor :first_name, :last_name
  end

  describe 'Creation' do

    it 'Can be saved as raw hash' do
      User.documents.should==[] # Empty by default
      u = User.new first_name: 'Bob', last_name: 'Mould'
      u.perform_create
      u.first_name.should=='Bob'
      User.documents.size.should==1
      User.documents[0].should==u.to_h # Data is the hash
    end

    class Tomato
      include PopulateMe::Document
      attr_accessor :taste
    end

    it 'Can be recreated from the hash saved' do
      tom = Tomato.new taste: 'good'
      tom.perform_create
      Tomato.documents[0].should==tom.to_h
      retrieved = Tomato.from_hash(Tomato.documents[0])
      retrieved.new?.should==false
      retrieved.should==tom
    end

    it 'Can mark the document as new or not when recreating from hash' do
      retrieved = Tomato.from_hash(Tomato.documents[0].merge('_is_new'=>true))
      retrieved.new?.should==true
      retrieved.to_h.should==Tomato.documents[0]
    end

    it 'Raises if trying to create from something that is not a Hash' do
      lambda{Tomato.from_hash(nil)}.should.raise(TypeError)
      lambda{Tomato.from_hash(42)}.should.raise(TypeError)
    end

    # it 'Can be created from Post' do
    # end

  end

  class Garlic
    include PopulateMe::Document
    attr_accessor :strength, :shape
  end

  describe 'Update' do

    it 'Raises on update if the original does not exist' do
      g = Garlic.new id: 'xxx', strength: 5
      lambda{ g.perform_update }.should.raise(PopulateMe::MissingDocumentError)
    end

    it 'Raises on update if the document has no ID' do
      g = Garlic.new id: 'xxx', strength: 3
      g.perform_create
      g.id = nil
      lambda{ g.perform_update }.should.raise(PopulateMe::MissingDocumentError)
    end

    it 'Updates correctly' do
      g = Garlic.new id: 'xxx', shape: 'curvy'
      g.perform_update
      Garlic.documents[0]['shape'].should=='curvy'
      Garlic.documents[0]['strength'].should==nil
    end

  end

  class Ball
    include PopulateMe::Document
    attr_accessor :diameter
  end

  describe 'Deletion' do

    it 'Raises on delete if the entry does not exist' do
      b = Ball.new id: 'xxx', diameter: 5
      lambda{ b.perform_delete }.should.raise(PopulateMe::MissingDocumentError)
    end

    it 'Raises on delete if the document has no ID' do
      b = Ball.new id: 'xxx', diameter: 3
      b.perform_create
      b.id = nil
      lambda{ b.perform_delete }.should.raise(PopulateMe::MissingDocumentError)
    end

    it 'Deletes correctly' do
      b = Ball.new id: 'yyy', diameter: 5
      b.perform_create
      Ball.documents.find{|d| d['id']=='yyy' }.should!=nil
      b.perform_delete
      Ball.documents.find{|d| d['id']=='yyy' }.should==nil
    end

  end

  class Haircut
    include PopulateMe::Document
    attr_accessor :name
  end

  describe 'Comparison' do

    it 'Consider equal 2 documents with the same data' do
      Haircut.new.should==Haircut.new
      Haircut.new(name: 'shaved').should==Haircut.new(name: 'shaved')
      Haircut.new.should!=nil
      Haircut.new.should!=String.new
    end

  end

  describe 'Find by ID' do

    it 'Has a class method to get the entry of a specific ID as an object' do
      Haircut.new(id: 123, name: 'pigtails').perform_create
      Haircut.new(id: '123', name: 'spikes').perform_create
      Haircut[123].name.should=='pigtails'
      Haircut['123'].name.should=='spikes'
    end

    it 'Returns nil if document does not exist' do
      Haircut['abc'].should==nil
    end

  end

  class Dodgy
    include PopulateMe::Document
    attr_accessor :prohibited, :number, :_log
    def validate
      self.number = self.number.to_i unless self.number.is_a? Integer
      error_on(:number, 'Is too high') if self.number==15
      error_on(:prohibited,'Is not allowed') unless prohibited.nil?
      error_on(:prohibited,'Is not good') unless prohibited.nil?
    end
    before :validate do
      @_log ||= ''
      @_log << self.errors.size.to_s
    end
    after :validate do
      @_log ||= ''
      @_log << self.errors.size.to_s
    end
  end

  describe 'Validation' do

    it 'Handles validations' do
      u = Dodgy.new
      u.errors.should=={}
      u.valid?.should==true
      u.prohibited = 'I dare'
      u.valid?.should==false
      u.errors[:prohibited].should==['Is not allowed','Is not good']
      u.prohibited = nil
      u.valid?.should==true
      u.number = 15
      u.number.should==15
      u.valid?.should==false
    end

    it 'Uses callbacks around validation' do
      d = Dodgy.new prohibited: 'I dare'
      d.valid?.should==false
      d._log.should=='01'
    end

  end

  class Death
    include PopulateMe::Document
    attr_accessor :pain_level, :was_alive, :is_dead
    before :delete do
      @was_alive = !self.class[self.id].nil?
    end
    after :delete do
      @is_dead = self.class[self.id].nil?
    end
  end

  describe 'High level deletion' do

    it 'Uses callbacks on the high level deletion method' do
      death = Death.new pain_level: 5, id: '123'
      death.perform_create
      death._is_new = false
      Death['123'].pain_level.should==5
      death.delete
      death.new?.should==true
      Death['123'].should==nil
      death.was_alive.should==true
      death.is_dead.should==true
    end

  end

  class SuperHero
    include PopulateMe::Document
    attr_accessor :name, :power, :_log
    def validate
      error_on(:power,'Needed') if power.nil?
    end

    before(:save) { @_log = '' }
    before(:create) { @_log << 'Just ' }
    after(:create) { @_log << 'born' }
    before(:update) { @_log << 'Now ' }
    after(:update) { @_log << 'updated' }
    after(:save) { @_log << '.' }
  end

  describe 'High level saving' do

    it 'Creates or updates depending on if the document is new or not' do
      hero = SuperHero.new name: 'Hulk', power: 'anger'
      hero.save
      SuperHero.documents.size.should==1
      hero.power = 'uncontrolled anger'
      hero.save
      SuperHero.documents.size.should==1
      SuperHero.documents[0]['power'].should=='uncontrolled anger'
    end

    it 'Does not save if the document is not valid' do
      hero = SuperHero.new id: 'spidey', name: 'Spiderman'
      hero.valid?.should==false
      hero.save
      SuperHero['spidey'].should==nil
    end

    it 'Uses the callbacks' do
      hero = SuperHero.new name: 'Torch', power: 'fire'
      hero.save
      hero.id.should!=nil
      hero.new?.should==false
      hero._log.should=='Just born.'
      hero.power = 'flying fire'
      hero.save
      hero._log.should=='Now updated.'
    end

  end

  describe 'Composite document' do

    class CookBook
      include PopulateMe::Document
      attr_accessor :title
      def recipes; @recipes ||= []; end
      EXAMPLE = {
        '_class'=>'CookBook',
        'title'=>'Cakes',
        'recipes'=>[
          {
            '_class'=>'CookBook::Recipe',
            'name'=>'Chocolate Cake',
            'ingredients'=>[{'name'=>'Chocolate','_class'=>'CookBook::Recipe::Ingredient'}]
          },
          {
            '_class'=>'CookBook::Recipe',
            'name'=>'Pound Cake',
            'ingredients'=>[{'name'=>'Egg','_class'=>'CookBook::Recipe::Ingredient'}]
          }
        ]
      }
      before :cook, :recurse_callback
    end
    class CookBook::Recipe
      include PopulateMe::Document
      attr_accessor :name, :_log
      def ingredients; @ingredients ||= []; end
      before :cook, :recurse_callback
      before :cook do
        @_log = 'Learn'
      end
    end
    class CookBook::Recipe::Ingredient
      include PopulateMe::Document
      attr_accessor :name, :_log
      def validate
        error_on(:name,'Dangerous') if self.name=='Poison'
      end
      before :cook do
        @_log = 'Smell'
      end

      [:save,:create,:update,:delete].each do |cb|
        before cb, :log_cb
        after cb, :log_cb
      end
      def log_cb name
        @_log ||= ''
        @_log << "#{name} "
      end
    end

    it 'Turns into a hash with string keys' do
      book = CookBook.new title: 'Cakes'
      rcp1 = CookBook::Recipe.new name: 'Chocolate Cake'
      rcp2 = CookBook::Recipe.new name: 'Pound Cake'
      choc = CookBook::Recipe::Ingredient.new name: 'Chocolate'
      egg = CookBook::Recipe::Ingredient.new name: 'Egg'
      rcp1.ingredients << choc
      rcp2.ingredients << egg
      book.recipes << rcp1
      book.recipes << rcp2
      book.to_h.should==CookBook::EXAMPLE
    end

    it 'Can be recreated from the hash saved' do
      book = CookBook.from_hash(CookBook::EXAMPLE)
      book.title.should=='Cakes'
      book.recipes[1].name.should=='Pound Cake'
      book.recipes[1].ingredients[0].name=='Egg'
    end

    it 'Validates a document if embeded documents are valid' do
      book = CookBook.from_hash(CookBook::EXAMPLE)
      book.recipes[0].ingredients[0].valid?.should==true
      book.recipes[0].valid?.should==true
      book.valid?.should==true
    end

    it 'Does not validate a document if embeded documents are not valid' do
      book = CookBook.from_hash(CookBook::EXAMPLE)
      book.recipes[0].ingredients[0].name = 'Poison'
      book.recipes[0].ingredients[0].valid?.should==false
      book.recipes[0].valid?.should==false
      book.valid?.should==false
    end

    it 'Has a special method for recursively execute a callback' do
      book = CookBook.from_hash(CookBook::EXAMPLE)
      book.recipes[0].ingredients[0]._log.should==nil
      book.recipes[0]._log.should==nil
      book.exec_callback(:before_cook)
      book.recipes[0].ingredients[0]._log.should=='Smell'
      book.recipes[0]._log.should=='Learn'
    end

    it 'Has all the default recursive callbacks registered' do
      # [:save,:create,:update].each do |cb|
      #   CookBook.callbacks["before_#{cb}".to_sym].include?(:recurse_callback).should==true
      #   CookBook.callbacks["after_#{cb}".to_sym].include?(:recurse_callback).should==true
      # end
      book = CookBook.from_hash(CookBook::EXAMPLE)
      expected_log = ''
      [:save,:create,:update,:delete].each do |cb|
        [:before, :after].each do |when_cb|
          book.exec_callback("#{when_cb}_#{cb}")
          expected_log << "#{when_cb}_#{cb} "
        end
      end
      book.recipes[0].ingredients[0]._log.should==expected_log
    end

  end

end

