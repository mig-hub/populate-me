require 'bacon'
$:.unshift File.expand_path('../../lib', __FILE__)
require 'populate_me/mongo'
require 'mongo'

MONGO = Mongo::Connection.new
MONGO.drop_database('populate-me-test')
DB    = MONGO['populate-me-test']


describe 'PopulateMe::Mongo' do
  # PopulateMe::Mongo is the Mongo specific extention for 
  # Document.
  #
  # It contains what is specific to a Mongo
  # database.

  class CatFish
    include PopulateMe::Mongo
    field :name
  end


  it 'Includes Document Module' do 
    CatFish.to_s.should == "Cat Fish"
    CatFish.new(name: "Fred").to_s.should == "Fred"
  end

  it "Has _id as persistent variable if set" do 
    CatFish.new(name: "hank").persistent_instance_variables.should == [:@name]
    CatFish.new(id: "bbbbb", name: "honk").persistent_instance_variables.should == [:@_id, :@name]
  end

  describe 'Database connection' do 

    it 'Should have db set by default' do 
      CatFish.db.should == DB
    end

    # it 'Should override db' do 
    #   FAKEDB = MONGO['fake-populate-me-db']
    #   CatFish.db(FAKEDB)
    #   CatFish.db.should == FAKEDB
    #   CatFish.db(DB)
    #   CatFish.db.should == DB
    # end

    # it 'Should raise DB not set! error if DB not set' do
    #   TEMP = DB
    #   # Object.remove_const :DB
    #   Object.send(:remove_const, :DB)
    #   lambda { CatFish.db }.should.raise(StandardError)
    #   DB = TEMP
    #   CatFish.db.should == DB
    # end

    it 'Should set DB collection to class name by default' do 
      CatFish.collection_name.should == "CatFish"
    end

    it 'Should override db collection name' do 
      CatFish.collection_name('DogFish')
      CatFish.collection_name.should == "DogFish"
      CatFish.collection_name('CatFish')
      CatFish.collection_name.should == "CatFish"
    end 

    it 'Should have collection set by default' do 
      CatFish.collection.name.should == DB['CatFish'].name
    end

  end

  describe 'Low level CRUD' do 

    it 'Should create' do
      fred = CatFish.new(id: "lll", name: "Fred")
      fred.perform_create
      jerry = CatFish.new(id: "mmm", name: "Jerry")
      jerry.perform_create
      CatFish.collection.count.should == 2
    end

    it 'Should create with custom id' do 
      tom = CatFish.new(id: "dddd", name: "tom")
      id = tom.perform_create
      id.should == "dddd"
    end

    it 'Should update' do 
      jason = CatFish.new(name: "jason")
      jason.perform_create
      jason.name = "billy"
      jason.perform_update
      CatFish.collection.find_one({'_id'=> jason.id})['name'].should== "billy"
    end

    it "Should get correct item" do 
      jackson_id = CatFish.new(name: "jackson").perform_create
      CatFish[jackson_id].name.should == "jackson"
      CatFish[jackson_id.to_s].name.should == "jackson"
      CatFish["nonexistentid"].should == nil

      regular_fish_id = CatFish.new(id: 87, name: "regular").perform_create
      # need to test with .to_s
      CatFish[regular_fish_id].name.should == "regular"
    end


    it 'Should delete' do
      herbert = CatFish.new(name: "herbert")
      herbert.perform_create
      CatFish.collection.find_one({"_id"=> herbert.id}).should!=nil
      herbert.perform_delete
      CatFish.collection.find_one({"_id"=> herbert.id}).should==nil
    end

    it 'Should not save to the document class variable' do 
      CatFish.documents.should == []
    end

  end

  describe 'High level CRUD' do 

    it 'Should use after_save callback' do 
      danny = CatFish.new(name: "danny")
      danny.new?.should == true
      danny.save
      CatFish.collection.find_one({"_id"=> danny.id}).should != nil
      danny.new?.should == false
    end

  end

end

MONGO.drop_database('populate-me-test')

