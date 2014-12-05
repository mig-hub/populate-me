require 'bacon'
$:.unshift File.expand_path('../../lib', __FILE__)
require 'populate_me/mongo'
require 'mongo'

MONGO = Mongo::Connection.new
MONGO.drop_database('populate-me-test')
MONGO.drop_database('populate-me-test-other')
DB = MONGO['populate-me-test']
OTHER_DB = MONGO['populate-me-test-other']


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
  module Paradise
    class CatFish
      include PopulateMe::Mongo
      field :name
    end
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

    it 'Can override db' do 
      CatFish.db(OTHER_DB)
      CatFish.db.should == OTHER_DB
      CatFish.db(DB)
      CatFish.db.should == DB
    end

    it 'Should set DB collection to dasherized full class name by default' do 
      CatFish.collection_name.should == "cat-fish"
      Paradise::CatFish.collection_name.should == "paradise--cat-fish"
    end

    it 'Should override db collection name' do 
      CatFish.collection_name('dog-fish')
      CatFish.collection_name.should == "dog-fish"
      CatFish.collection_name('cat-fish')
      CatFish.collection_name.should == "cat-fish"
    end 

    it 'Finds collection in DB' do 
      CatFish.collection.name.should == DB['cat-fish'].name
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
      CatFish.admin_get(jackson_id).name.should == "jackson"
      CatFish.admin_get(jackson_id.to_s).name.should == "jackson"
      CatFish.admin_get("nonexistentid").should == nil

      regular_fish_id = CatFish.new(id: 87, name: "regular").perform_create
      # need to test with .to_s
      CatFish.admin_get(regular_fish_id).name.should == "regular"
    end

    it 'Should have the [] shortcut for admin_get' do
      CatFish.admin_get(87).should == CatFish[87]
    end

    it 'Should admin_find correctly' do
      CatFish.admin_find.size.should==CatFish.collection.count
      CatFish.admin_find.is_a?(Array).should==true
      CatFish.admin_find(query: {name: 'regular'}).size.should==CatFish.collection.find(name: 'regular').count
      CatFish.admin_find(query: {name: 'regular'})[0].id.should==87
    end

    it 'Should delete' do
      herbert = CatFish.new(name: "herbert")
      herbert.perform_create
      CatFish.collection.find_one({"_id"=> herbert.id}).should!=nil
      herbert.perform_delete
      CatFish.collection.find_one({"_id"=> herbert.id}).should==nil
    end

    it 'Should not save to the @@documents class variable' do 
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
MONGO.drop_database('populate-me-test-other')

