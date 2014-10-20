require 'bacon'
$:.unshift File.expand_path('../../lib', __FILE__)
require 'populate_me/mongo'
require 'mongo'

MONGO = Mongo::Connection.new
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


  describe 'Data base connection' do 

    it 'Should have db set by default' do 
      CatFish.db.should == DB
    end

    it 'Should override db' do 
      FAKEDB = MONGO['fake-populate-me-db']
      CatFish.db(FAKEDB)
      CatFish.db.should == FAKEDB
      CatFish.db(DB)
      CatFish.db.should == DB
    end

    # it 'Should raise DB not set ! error if DB not set' do 

    # end

    it 'Should set db collection to class name by default' do 
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


  # describe 'CRUD' do 
  #   it 'Should create' do
  #     fred = CatFish.new(id: "lll", name: "Fred")
  #     fred.perform_create
  #     fredo = CatFish.documents.find{|d| d['id']=='lll'}
  #     fredo['name'].should == "Fred"
  #   end

  #   it 'Should update' do 
  #     jason = CatFish.new(id: "vvv", name: "jason")
  #     jason.perform_create
  #     jason.name = "billy"
  #     jason.perform_update
  #     CatFish.documents.find{|d| d['id']=='vvv'}['name'].should=='billy'
  #   end

  #   it 'Should delete' do
  #     herbert = CatFish.new id: "ccc", name: "herbert"
  #     herbert.perform_create
  #     CatFish.documents.find{|d| d['id']=='ccc'}.should!=nil
  #     herbert.perform_delete
  #     CatFish.documents.find{|d| d['id']=='ccc'}.should==nil
  #   end

  #   it 'Should not save to the document class variable' do 
  #     CatFish.documents.should == []
  #   end
  # end

end

MONGO.drop_database['populate-me-test']
