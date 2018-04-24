require 'helper'
require 'populate_me/mongo'
# require 'mongo'

Mongo::Logger.logger.level = Logger::ERROR

MONGO = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'populate-me-test')
DB = MONGO.database
DB.drop
OTHER_MONGO = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'populate-me-test-other')
OTHER_DB = OTHER_MONGO.database
OTHER_DB.drop
PopulateMe::Mongo.set :db, DB


describe 'PopulateMe::Mongo' do
  # PopulateMe::Mongo is the Mongo specific extention for 
  # Document.
  #
  # It contains what is specific to a Mongo
  # database.

  # parallelize_me!

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

    class NoMongoDB < PopulateMe::Mongo; set :db, nil; end

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

    class LowFish < PopulateMe::Mongo
      field :name
      field :lastname
    end

    before do
      LowFish.collection.drop
    end

    it 'Should create' do
      fred = LowFish.new(name: "Fred")
      id = fred.perform_create
      assert_equal id, fred.id 
      refute_nil LowFish.collection.find({'name'=>"Fred"}).first
      LowFish.collection.delete_one({'name'=>'Fred'})
    end

    it 'Should create with custom id' do 
      dddd = LowFish.new(id: "dddd", name: "tom")
      id = dddd.perform_create
      assert_equal "dddd", id
    end

    it 'Should update' do 
      jason = LowFish.new(name: "jason")
      jason.perform_create
      jason.name = "billy"
      jason.perform_update
      assert_equal  "billy", LowFish.collection.find({'_id'=> jason.id}).first['name']
    end

    it "Should get correct item" do 
      jackson_id = LowFish.new(name: "jackson").perform_create
      assert_equal "jackson", LowFish.admin_get(jackson_id).name
      assert_equal "jackson", LowFish.admin_get(jackson_id.to_s).name
      assert_nil LowFish.admin_get("nonexistentid")

      regular_fish_id = LowFish.new(id: 87, name: "regular").perform_create
      # need to test with .to_s
      assert_equal "regular", LowFish.admin_get(regular_fish_id).name
    end

    it 'Should have the [] shortcut for admin_get' do
      LowFish.collection.insert_one(_id: 42, name: "H2G2")
      assert_equal LowFish[42], LowFish.admin_get(42)
    end

    it 'Should admin_find correctly' do
      LowFish.collection.insert_one(_id: 10, name: "Arya")
      LowFish.collection.insert_one(_id: 20, name: "Bran")
      LowFish.collection.insert_one(_id: 30, name: "Arya")
      LowFish.collection.insert_one(_id: 40, name: "Bran")
      items = LowFish.admin_find
      assert items.is_a?(Array)
      assert 4, items.count
      assert_equal 10, items[0].id
      items = LowFish.admin_find query: {name: 'Bran'}
      assert items.is_a?(Array)
      assert 2, items.count
      assert_equal 20, items[0].id
    end

    it 'Should admin_find_first correctly' do
      LowFish.collection.insert_one(_id: 10, name: "Arya")
      LowFish.collection.insert_one(_id: 20, name: "Bran")
      LowFish.collection.insert_one(_id: 30, name: "Arya")
      LowFish.collection.insert_one(_id: 40, name: "Bran")
      item = LowFish.admin_find_first
      assert_equal 10, item.id
      item = LowFish.admin_find_first query: {name: "Bran"}
      assert_equal 20, item.id
    end

    it 'Should admin_find while turning fields option into a projection option' do
      LowFish.collection.insert_one(_id: 42, name: "John", lastname: "Doe")
      found = LowFish.admin_find(query: {lastname: "Doe"}, fields: ['_id', 'lastname'])[0]
      assert_equal 42, found.id
      assert_nil found.name
    end

    it 'Should delete' do
      herbert = LowFish.new(name: "herbert")
      herbert.perform_create
      refute_nil LowFish.collection.find({"_id"=> herbert.id}).first
      herbert.perform_delete
      assert_nil LowFish.collection.find({"_id"=> herbert.id}).first
    end

    it 'Should not save to the @@documents class variable' do 
      LowFish.collection.insert_one(_id: 42, name: "H2G2")
      assert_equal [], LowFish.documents
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
      assert_equal 'Tony', MongoSoldier.sort_by([[:name, -1]]).admin_find[0].name
      assert_equal 'Tony', MongoSoldier.sort_by({name: -1}).admin_find[0].name
    end

  end

  describe 'Manual Sorting' do

    class MongoChampion < PopulateMe::Mongo
      field :position
      field :reversed, direction: :desc
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

    it 'Sets the indexes taking direction into account' do
      MongoChampion.set_indexes(:reversed,['b','a','c'])
      assert_equal 1, MongoChampion.admin_get('a').reversed
      assert_equal 2, MongoChampion.admin_get('b').reversed
      assert_equal 0, MongoChampion.admin_get('c').reversed
    end

    it 'Sets the indexes correctly even if some ids are not string' do
      MongoChampion.collection.drop
      MongoChampion.new(id: 'a').perform_create
      MongoChampion.new(id: BSON::ObjectId.from_string("507f1f77bcf86cd799439011")).perform_create
      MongoChampion.new(id: BSON::ObjectId.from_string("507f191e810c19729de860ea")).perform_create
      MongoChampion.set_indexes(:position,["507f1f77bcf86cd799439011",'a',"507f191e810c19729de860ea"])
      assert_equal 0, MongoChampion.admin_get("507f1f77bcf86cd799439011").position
      assert_equal 1, MongoChampion.admin_get('a').position
      assert_equal 2, MongoChampion.admin_get("507f191e810c19729de860ea").position
    end
  end

  describe '::admin_distinct' do

    class MongoDistinction < PopulateMe::Mongo
      attr_accessor :title, :age
    end

    before do
      MongoDistinction.collection.drop
    end

    it 'Can list all distinct values' do
      MongoDistinction.new(title: 'Lord').save
      MongoDistinction.new(title: 'Lord').save
      MongoDistinction.new.save
      MongoDistinction.new(title: 'Chevalier').save
      MongoDistinction.new(title: 'Baron').save
      MongoDistinction.new(title: 'Baron').save
      result = MongoDistinction.admin_distinct :title
      assert_instance_of Array, result
      assert_equal 3, result.size
      assert_includes result, 'Lord'
      assert_includes result, 'Chevalier'
      assert_includes result, 'Baron'
    end

    it 'Can list all distinct values for a specific selector' do
      MongoDistinction.new(title: 'Chevalier', age: 33).save
      MongoDistinction.new(title: 'Chevalier', age: 34).save
      MongoDistinction.new(title: 'Baron', age: 35).save
      MongoDistinction.new(title: 'Baron', age: 36).save
      result = MongoDistinction.admin_distinct :age, query: {title: 'Baron'}
      assert_instance_of Array, result
      assert_equal 2, result.size
      assert_includes result, 35
      assert_includes result, 36
    end

  end

end

DB.drop
OTHER_DB.drop

