require 'bacon'
$:.unshift File.expand_path('../../lib', __FILE__)
require 'populate_me/api'

class MockModel

  def initialize(hash)
    @hash = hash
  end

  def self.api_get(id)
    return nil if PopulateMe::Utils.blank?(id)||id=='666'
    self.new({'id'=>id.to_i,'fullname'=>'Full Name'})
  end

  def api_delete
    @hash.update({'fullname'=>'Bobby'})
    self
  end

  def to_h
    @hash
  end
end

API = Rack::MockRequest.new(PopulateMe::API.new)

describe 'PopulateMe::API' do

  def should_not_found(res)
    json = JSON.parse(res.body)
    res.content_type.should=='application/json'
    res.status.should==404
    res.headers['X-Cascade'].should=='pass'
    json['success'].should==false
    json['message'].should=='Not Found'
  end

  def successful_instance(res,id)
    json = JSON.parse(res.body)
    res.content_type.should=='application/json'
    res.status.should==200
    json['success'].should==true
    json['data']['id'].should==id
    json['data']['fullname'].should=='Full Name'
  end

  def successful_deletion(res,id)
    json = JSON.parse(res.body)
    res.content_type.should=='application/json'
    res.status.should==200
    json['success'].should==true
    json['message'].should=='Deleted Successfully'
    json['data']['id'].should==id
    json['data']['fullname'].should=='Bobby'
  end

  describe 'GET /:model/:id' do
    it 'Sends a not-found when the model is not a class' do
      res = API.get('/wizz/42')
      should_not_found(res)
    end
    # it 'Sends not-found when the model is not provided' do
    #   res = API.get('//42')
    #   should_not_found(res)
    # end
    it 'Sends not-found when the model is a class but not a model' do
      res = API.get('/string/42')
      should_not_found(res)
    end
    it 'Sends not-found when the id is not provided' do
      res = API.get('/mock-model/')
      should_not_found(res)
    end
    it 'Sends not-found when the instance does not exist' do
      res = API.get('/mock-model/666')
      should_not_found(res)
    end
    it 'Sends the instance if it exists' do
      res = API.get('/mock-model/42')
      successful_instance(res,42)
    end
  end

  describe 'DELETE /:model/:id' do
    it 'Sends not-found if the instance does not exist' do
      res = API.delete('/mock-model/666')
      should_not_found(res)
    end
    it 'Returns a deletion response when the instance exists' do
      res = API.delete('/mock-model/42')
      successful_deletion(res,42)
    end
  end
end

