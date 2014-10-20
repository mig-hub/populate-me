require 'bacon'
$:.unshift File.expand_path('../../lib', __FILE__)
require 'populate_me/mongo'


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


end