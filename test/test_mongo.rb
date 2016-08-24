require 'helper'
require 'populate_me/mongo'
# require 'mongo'

MONGO = Mongo::Connection.new
MONGO.drop_database('populate-me-test')
MONGO.drop_database('populate-me-test-other')
DB = MONGO['populate-me-test']
OTHER_DB = MONGO['populate-me-test-other']
class NoMongoDB < PopulateMe::Mongo; end
PopulateMe::Mongo.set :db, DB


describe 'PopulateMe::Mongo' do
  # PopulateMe::Mongo is the Mongo specific extention for 
  # Document.
  #
  # It contains what is specific to a Mongo
  # database.

  parallelize_me!

  class CatFish < PopulateMe::Mongo
    field :name
  end
  module Paradise
    class CatFish < PopulateMe::Mongo
      field :name
    end
  end

  it 'Includes Document Module' do 
    assert_equal "Cat Fish", CatFish.to_s
    assert_equal "Fred", CatFish.new(name: "Fred").to_s
  end

  it "Has _id as persistent variable if set" do 
    assert_equal [:@name], CatFish.new(name: "hank").persistent_instance_variables
    cf = CatFish.new(id: "bbbbb", name: "honk")
    assert cf.persistent_instance_variables.include?(:@_id)
    assert cf.persistent_instance_variables.include?(:@name)
  end

  describe 'Database connection' do 

    it 'Should raise if db is not set' do 
      assert_raises(PopulateMe::MissingMongoDBError) do
        NoMongoDB.collection
      end
    end

    it 'Should have db set by the parent class' do
      assert_equal DB, CatFish.settings.db
    end

    it 'Can override db' do 
      CatFish.set :db, OTHER_DB
      assert_equal OTHER_DB, CatFish.settings.db
      CatFish.set :db, DB
      assert_equal DB, CatFish.settings.db
    end

    it 'Should set DB collection to dasherized full class name by default' do 
      assert_equal "cat-fish", CatFish.settings.collection_name
      assert_equal "paradise--cat-fish", Paradise::CatFish.settings.collection_name
    end

    it 'Finds collection in DB' do 
      assert_equal DB['cat-fish'].name, CatFish.collection.name
    end

  end

  describe 'Low level CRUD' do 

    before do
      CatFish.collection.drop
      CatFish.collection.insert(id: 42, name: "H2G2")
    end

    it 'Should create' do
      CatFish.new(name: "Fred").perform_create
      refute_nil CatFish.collection.find_one({'name'=>"Fred"})
    end

    it 'Should create with custom id' do 
      tom = CatFish.new(id: "dddd", name: "tom")
      id = tom.perform_create
      assert_equal "dddd", id
    end

    it 'Should update' do 
      jason = CatFish.new(name: "jason")
      jason.perform_create
      jason.name = "billy"
      jason.perform_update
      assert_equal  "billy", CatFish.collection.find_one({'_id'=> jason.id})['name']
    end

    it "Should get correct item" do 
      jackson_id = CatFish.new(name: "jackson").perform_create
      assert_equal "jackson", CatFish.admin_get(jackson_id).name
      assert_equal "jackson", CatFish.admin_get(jackson_id.to_s).name
      assert_nil CatFish.admin_get("nonexistentid")

      regular_fish_id = CatFish.new(id: 87, name: "regular").perform_create
      # need to test with .to_s
      assert_equal "regular", CatFish.admin_get(regular_fish_id).name
    end

    it 'Should have the [] shortcut for admin_get' do
      assert_equal CatFish[42], CatFish.admin_get(42)
    end

    it 'Should admin_find correctly' do
      assert_equal CatFish.collection.count, CatFish.admin_find.size
      assert CatFish.admin_find.is_a?(Array)
      assert_equal CatFish.collection.find(name: 'H2G2').count, CatFish.admin_find(query: {name: 'H2G2'}).size
      assert_equal 42, CatFish.admin_find(query: {name: 'H2G2'})[0].id
    end

    it 'Should delete' do
      herbert = CatFish.new(name: "herbert")
      herbert.perform_create
      refute_nil CatFish.collection.find_one({"_id"=> herbert.id})
      herbert.perform_delete
      assert_nil CatFish.collection.find_one({"_id"=> herbert.id})
    end

    it 'Should not save to the @@documents class variable' do 
      assert_equal [], CatFish.documents
    end

  end

  describe 'High level CRUD' do 

    it 'Should use callbacks' do 
      danny = CatFish.new(name: "danny")
      assert_nil danny.id
      assert danny.new?
      danny.save
      refute_nil danny.id
      refute danny.new?
    end

  end

  describe 'Default Sorting' do

    class MongoSoldier < PopulateMe::Mongo
      field :name
      field :position
    end

    before do
      MongoSoldier.collection.drop
      MongoSoldier.new(name: 'Bob', position: 2).perform_create
      MongoSoldier.new(name: 'Albert', position: 3).perform_create
      MongoSoldier.new(name: 'Tony', position: 1).perform_create
    end

    it 'Uses Doc::sort_by to determine the order' do
      assert_equal 'Albert', MongoSoldier.sort_by(:name).admin_find[0].name
      assert_equal 'Tony', MongoSoldier.sort_by(:name,:desc).admin_find[0].name
      assert_equal 1, MongoSoldier.sort_by(:position).admin_find[0].position
      assert_raises(ArgumentError) do
        MongoSoldier.sort_by(:name,0)
      end
      assert_raises(ArgumentError) do
        MongoSoldier.sort_by(:namespace)
      end
    end

    it 'Can write Mongo-specific sort if a Hash or an Array is passed' do
      assert_equal 'Tony', MongoSoldier.sort_by([[:name,:desc]]).admin_find[0].name
      assert_equal 'Tony', MongoSoldier.sort_by({name: :desc}).admin_find[0].name
    end

  end

  describe 'Manual Sorting' do

    class MongoChampion < PopulateMe::Mongo
      field :position
    end

    before do
      MongoChampion.collection.drop
      MongoChampion.new(id: 'a').perform_create
      MongoChampion.new(id: 'b').perform_create
      MongoChampion.new(id: 'c').perform_create
    end

    it 'Sets the indexes on the provided field' do
      MongoChampion.set_indexes(:position,['b','a','c'])
      assert_equal 1, MongoChampion.admin_get('a').position
      assert_equal 0, MongoChampion.admin_get('b').position
      assert_equal 2, MongoChampion.admin_get('c').position
    end

  end

end

MONGO.drop_database('populate-me-test')
MONGO.drop_database('populate-me-test-other')
