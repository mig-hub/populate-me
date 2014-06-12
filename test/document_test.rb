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
    obj.set 'size'=>4
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

  it 'Can be saved as raw hash' do
    User.documents.should==[] # Empty by default
    u = User.new first_name: 'Bob', last_name: 'Mould'
    u.new?.should==true # New when created with new
    u.perform_create
    u.new?.should==false # Not new once saved
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

end

