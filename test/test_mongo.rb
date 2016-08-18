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
    _(CatFish.to_s).must_equal "Cat Fish"
    _(CatFish.new(name: "Fred").to_s).must_equal "Fred"
  end

  it "Has _id as persistent variable if set" do 
    _(CatFish.new(name: "hank").persistent_instance_variables).must_equal [:@name]
    cf = CatFish.new(id: "bbbbb", name: "honk")
    _(cf.persistent_instance_variables.include?(:@_id)).must_equal true
    _(cf.persistent_instance_variables.include?(:@name)).must_equal true
  end

  describe 'Database connection' do 

    it 'Should raise if db is not set' do 
      _{ NoMongoDB.collection }.must_raise(PopulateMe::MissingMongoDBError)
    end

    it 'Should have db set by the parent class' do
      _(CatFish.settings.db).must_equal DB
    end

    it 'Can override db' do 
      CatFish.set :db, OTHER_DB
      _(CatFish.settings.db).must_equal OTHER_DB
      CatFish.set :db, DB
      _(CatFish.settings.db).must_equal DB
    end

    it 'Should set DB collection to dasherized full class name by default' do 
      _(CatFish.settings.collection_name).must_equal "cat-fish"
      _(Paradise::CatFish.settings.collection_name).must_equal "paradise--cat-fish"
    end

    it 'Finds collection in DB' do 
      _(CatFish.collection.name).must_equal DB['cat-fish'].name
    end

  end

  describe 'Low level CRUD' do 

    before do
      CatFish.collection.drop
      CatFish.collection.insert(id: 42, name: "H2G2")
    end

    it 'Should create' do
      CatFish.new(name: "Fred").perform_create
      _(CatFish.collection.find_one({'name'=>"Fred"})).wont_equal(nil)
    end

    it 'Should create with custom id' do 
      tom = CatFish.new(id: "dddd", name: "tom")
      id = tom.perform_create
      _(id).must_equal "dddd"
    end

    it 'Should update' do 
      jason = CatFish.new(name: "jason")
      jason.perform_create
      jason.name = "billy"
      jason.perform_update
      _(CatFish.collection.find_one({'_id'=> jason.id})['name']).must_equal  "billy"
    end

    it "Should get correct item" do 
      jackson_id = CatFish.new(name: "jackson").perform_create
      _(CatFish.admin_get(jackson_id).name).must_equal "jackson"
      _(CatFish.admin_get(jackson_id.to_s).name).must_equal "jackson"
      _(CatFish.admin_get("nonexistentid")).must_equal nil

      regular_fish_id = CatFish.new(id: 87, name: "regular").perform_create
      # need to test with .to_s
      _(CatFish.admin_get(regular_fish_id).name).must_equal "regular"
    end

    it 'Should have the [] shortcut for admin_get' do
      _(CatFish.admin_get(42)).must_equal CatFish[42]
    end

    it 'Should admin_find correctly' do
      _(CatFish.admin_find.size).must_equal CatFish.collection.count
      _(CatFish.admin_find.is_a?(Array)).must_equal true
      _(CatFish.admin_find(query: {name: 'H2G2'}).size).must_equal CatFish.collection.find(name: 'H2G2').count
      _(CatFish.admin_find(query: {name: 'H2G2'})[0].id).must_equal 42
    end

    it 'Should delete' do
      herbert = CatFish.new(name: "herbert")
      herbert.perform_create
      _(CatFish.collection.find_one({"_id"=> herbert.id})).wont_equal nil
      herbert.perform_delete
      _(CatFish.collection.find_one({"_id"=> herbert.id})).must_equal nil
    end

    it 'Should not save to the @@documents class variable' do 
      _(CatFish.documents).must_equal []
    end

  end

  describe 'High level CRUD' do 

    it 'Should use callbacks' do 
      danny = CatFish.new(name: "danny")
      _(danny.id).must_equal nil
      _(danny.new?).must_equal true
      danny.save
      _(danny.id).wont_equal nil
      _(danny.new?).must_equal false
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
      _(MongoSoldier.sort_by(:name).admin_find[0].name).must_equal 'Albert'
      _(MongoSoldier.sort_by(:name,:desc).admin_find[0].name).must_equal 'Tony'
      _(MongoSoldier.sort_by(:position).admin_find[0].position).must_equal 1
      _{ MongoSoldier.sort_by(:name,0) }.must_raise(ArgumentError)
      _{ MongoSoldier.sort_by(:namespace) }.must_raise(ArgumentError)
    end

    it 'Can write Mongo-specific sort if a Hash or an Array is passed' do
      _(MongoSoldier.sort_by([[:name,:desc]]).admin_find[0].name).must_equal 'Tony'
      _(MongoSoldier.sort_by({name: :desc}).admin_find[0].name).must_equal 'Tony'
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
      _(MongoChampion.admin_get('a').position).must_equal 1
      _(MongoChampion.admin_get('b').position).must_equal 0
      _(MongoChampion.admin_get('c').position).must_equal 2
    end

  end

end

MONGO.drop_database('populate-me-test')
MONGO.drop_database('populate-me-test-other')

