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

  it 'Can set variables with a hash' do
    obj = Egg.new
    obj.set size: 1, taste: 'good'
    obj.size.should==1
    obj.taste.should=='good'
    obj.set size: 4
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
  end

  it 'Can return a list of persistent instance variables' do
    # Only keys which do not start with an underscore are persistent
    obj = Egg.new size: 3, _hidden: 'secret'
    obj.size.should==3
    obj.taste.should==nil
    obj._hidden.should=='secret'
    obj.persistent_instance_variables.should==[:@size]
  end

  it 'Can be turned into a hash with string keys' do
    obj = Egg.new
    obj.to_h.should=={}
    obj.set size: 1, taste: 'good', _hidden: 'secret'
    obj._hidden.should=='secret'
    obj.to_h.should=={'size'=>1,'taste'=>'good'}
    obj.to_h.should==obj.to_hash
  end

  class User
    include PopulateMe::Document
    attr_accessor :first_name, :last_name
  end

  it 'Performs creation and add an ID if needed' do
    User.documents.should==[] # Empty by default
    u1 = User.new first_name: 'Bob', last_name: 'Mould'
    u1.new?.should==true # New when created with new
    the_id1 = u1.perform_create
    u1.new?.should==false # Not new once persistent
    the_id1.should!=nil
    u1.id.should==the_id1 
    u1.first_name.should=='Bob'
    u2 = User.new first_name: 'Joey', last_name: 'Ramone', _id: 'xxx'
    u2.id.should=='xxx'
    the_id2 = u2.perform_create
    the_id2.should=='xxx' # Kept the given ID
    u2.id.should=='xxx'
    u3 = User.new
    the_id3 = u3.perform_create
    the_id3.should!=the_id1 # Automatic is different each time
    User.documents.size.should==3
    User.documents[0].should==u1.to_h # Data is the hash
  end

  class Tomato
    include PopulateMe::Document
    attr_accessor :taste
  end

  it 'Can be recreated from the hash saved' do
    tom = Tomato.new taste: 'good'
    id = tom.perform_create
    tom.id.should==id
    Tomato.documents[0].should==tom.to_h
    retrieved = Tomato.from_hash(Tomato.documents[0])
    retrieved.new?.should==false
    retrieved.id.should==tom.id
    retrieved.should==tom
  end

  it 'Saves correctly' do
    User.documents.should==[]
    inst = User.new(
      first_name: 'Bob',
      last_name: 'Mould'
    )
    inst.new?.should==true
    inst.save
    inst.new?.should==false
    User.documents.size.should>0
    inst.id.should!=nil
    inst.to_h.should==User.documents[0]
    inst2 = User.new
    inst2.save
    inst2.id.should!=nil
    inst2.id.should!=inst.id
  end

  class Dodgy
    include PopulateMe::Document
    attr_accessor :prohibited, :number
    def validate
      number = number.to_i unless number.is_a? Integer
      error_on(:number, 'Is too high') if number==15
      error_on(:prohibited,'Is not allowed') unless prohibited.nil?
      error_on(:prohibited,'Is not good') unless prohibited.nil?
    end
  end

  it 'Handles validations' do
    u = Dodgy.new
    u._errors.should=={}
    u.valid?.should==true
    u.prohibited = 'I dare'
    u.valid?.should==false
    u._errors[:prohibited].should==['Is not allowed','Is not good']
    u.prohibited = nil
    u.valid?.should==true
    u.number = 15
    u.number.should==15
    u.valid?.should==false
  end

  # it 'Deletes correctly' do

  # end
end

