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
      obj.to_h.should=={}
      obj.set size: 1, taste: 'good', _hidden: 'secret'
      obj._hidden.should=='secret'
      obj.to_h.should=={'size'=>1,'taste'=>'good'}
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
    end

    it 'Registers callbacks as symbols or blocks' do
      Hamburger.callbacks.size.should==3
      Hamburger.callbacks[0].should==:bread
      Hamburger.callbacks[1].should==:cheese
      h = Hamburger.new taste: 'good'
      h.instance_eval(&Hamburger.callbacks[2]).should=='good'
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

    it 'Returns nil if trying to create from something that is not a Hash' do
      Tomato.from_hash(nil).should==nil
      Tomato.from_hash(42).should==nil
    end

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

  describe 'Find by ID' do

    it 'Has a class method to get the entry of a specific ID as an object' do
      Haircut.new(id: 123, name: 'pigtails').perform_create
      Haircut.new(id: '123', name: 'spikes').perform_create
      Haircut[123].name.should=='pigtails'
      Haircut['123'].name.should=='spikes'
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
    def before_validate
      super
      @_log ||= ''
      @_log << self.errors.size.to_s
    end
    def after_validate
      super
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
    def before_delete
      super
      @was_alive = !self.class[self.id].nil?
    end
    def after_delete
      super
      @is_dead = self.class[self.id].nil?
    end
  end

  describe 'High level deletion' do

    it 'Uses callbacks on the high level deletion method' do
      death = Death.new pain_level: 5, id: '123'
      death.perform_create
      Death['123'].pain_level.should==5
      death.delete
      Death['123'].should==nil
      death.was_alive.should==true
      death.is_dead.should==true
    end

  end

end

