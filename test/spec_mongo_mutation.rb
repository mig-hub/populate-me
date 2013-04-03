Encoding.default_internal = Encoding.default_external = Encoding::UTF_8 if RUBY_VERSION >= '1.9.0'

require 'rubygems'
require 'bacon'
require 'mongo'
$:.unshift './lib'
require 'populate_me/mongo'

MONGO = ::Mongo::MongoClient.new
class NoDB; include PopulateMe::Mongo::Plug; end
DB  = MONGO['test-mongo-mutation']

class Naked; include PopulateMe::Mongo::Plug; end

class Person
  include PopulateMe::Mongo::Plug
  slot "name" # no options
  slot "surname"
  slot "age", :type=>:integer, :default=>18
  image_slot "portrait"
  slot 'subscribed_on', :type=>:date, :default=>proc{Time.now}
end

class Address
  include PopulateMe::Mongo::Plug
  slot "body"
end

class Article
  include PopulateMe::Mongo::Plug
  slot 'title'
  slot 'content', :type=>:text
  image_slot
end

describe "PopulateMe::Mongo::Mutation" do
  
  describe ".db" do 
    it "Should be set to DB constant by default" do
      NoDB.db.should==nil
      Naked.db.should==DB
    end
  end
  
  shared "Empty BSON" do
    it "Should be set to an empty BSON ordered hash by default" do
      @bson.class.should==::BSON::OrderedHash
      @bson.empty?.should==true
    end
  end
  
  describe ".schema" do
    before { @bson = Naked.schema }
    behaves_like "Empty BSON"
  end
  
  describe ".relationships" do
    before { @bson = Naked.relationships }
    behaves_like "Empty BSON"
  end
  
  shared "Basic slot" do
    it "Adds the declared slot to the schema" do
      @klass.schema.key?(@key).should==true
    end
    it "Defines getters and setters" do
      @klass.new.respond_to?(@key).should==true
      @klass.new.respond_to?(@key+'=').should==true
    end
  end
  
  describe ".slot" do
    before { @klass = Person; @key = 'age' }
    behaves_like "Basic slot"
    it "Keeps the options in schema" do
      Person.schema['age'][:default].should==18
      Person.schema['age'][:type].should==:integer
    end
    it "Sets :type option to :string by default if not provided" do
      Person.schema['name'][:type].should==:string
    end
  end
  
  shared "Correctly typed" do
    it "Has the correct type" do
      @klass.schema[@key][:type].should==@type
    end
  end
  
  shared "Image slot" do
    describe "Reference slot" do
      before { @type = :attachment }
      behaves_like "Basic slot"
      behaves_like "Correctly typed"
    end
    describe "Tooltip slot" do
      before { @key = @key+'_tooltip'; @type = :string }
      behaves_like "Basic slot"
      behaves_like "Correctly typed"
    end
    describe "Alt text slot" do
      before { @key = @key+'_alternative_text'; @type = :string }
      behaves_like "Basic slot"
      behaves_like "Correctly typed"
    end
  end
  
  describe ".image_slot" do
    describe "Name provided" do
      before { @klass = Person; @key = 'portrait' }
      behaves_like "Image slot"
    end
    describe "Name not provided" do
      before { @klass = Article; @key = 'image' }
      behaves_like "Image slot"
    end
  end
  
  shared "Has error recipient" do
    it "Has an empty recipent for errors" do
      @inst.errors.should=={}
    end
  end
  
  describe "#initialize" do
    describe "With fields" do
      before { @inst = Person.new({'age'=>42, 'name'=>'Bozo', 'car'=>'Jaguar'}) }
      it "Should be flagged as new if the doc has no _id yet" do
        @inst.new?.should==true
      end
      it "Should not be flagged as new if the doc has an _id" do
        @inst['_id'] = 'abc'
        @inst.new?.should==false
      end
      it "Should pass all keys to the doc" do
        @inst['name'].should=='Bozo'
        @inst['car'].should=='Jaguar'
      end
      behaves_like "Has error recipient"
    end
    describe "Fresh new one" do
      before { @inst = Person.new }
      it "Should be flagged as new" do
        @inst.new?.should==true
      end
      it "Has default values correctly set" do
        @inst['age'].should==18 # direct value
        @inst['subscribed_on'].class.should==Time # with proc
      end
      behaves_like "Has error recipient"
    end
  end
  
  describe "#model" do
    it "Is a shortcut for self.class" do
      Naked.new.model.should==Naked
    end
  end

end

MONGO.drop_database('test-mongo-mutation')

