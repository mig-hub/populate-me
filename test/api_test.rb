require 'bacon'
$:.unshift File.expand_path('../../lib', __FILE__)

require 'populate_me/document'
class Band
  include PopulateMe::Document
  attr_accessor :name
end
Band.new(id: '1', name: 'Gang of Four').save
Band.new(id: '2', name: 'Autolux').save
Band.new(id: '3', name: 'Ramones').save

require 'populate_me/api'
API = Rack::MockRequest.new(PopulateMe::API.new)

describe 'PopulateMe::API' do

  # This middleware has the CRUD interface for
  # managing documents through a JSON-based API
  #
  # The API needs the Document class to implement these methods:
  # - Class.[]
  #   - Needs to be able to accept the ID as a string
  #   - The class is responsible for conversion
  #   - So a mix of different classes of IDs is not possible
  # - instance.to_h
  # - instance.save
  # - instance.delete

  def should_not_found(res)
    json = JSON.parse(res.body)
    res.content_type.should=='application/json'
    res.status.should==404
    res.headers['X-Cascade'].should=='pass'
    json['success'].should==false
    json['message'].should=='Not Found'
  end
  
  def successful_creation(res,obj)
    json = JSON.parse(res.body)
    res.content_type.should=='application/json'
    res.status.should==201
    json['success'].should==true
    json['message'].should=='Created Successfully'
    json['data'].should==obj.to_h
  end

  def successful_instance(res,obj)
    json = JSON.parse(res.body)
    res.content_type.should=='application/json'
    res.status.should==200
    json['success'].should==true
    json['data'].should==obj.to_h
  end

  def successful_deletion(res,obj)
    json = JSON.parse(res.body)
    res.content_type.should=='application/json'
    res.status.should==200
    json['success'].should==true
    json['message'].should=='Deleted Successfully'
    json['data'].should==obj.to_h
  end

  describe 'POST /:model' do

    it 'Creates successfully' do
      res = API.post('/band', {params: {data: {id: '4', name: 'Neurosis'}}})
      successful_creation(res,Band['4'])
    end

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
      res = API.get('/band/')
      should_not_found(res)
    end
    it 'Sends not-found when the instance does not exist' do
      res = API.get('/band/666')
      should_not_found(res)
    end
    it 'Sends the instance if it exists' do
      res = API.get('/band/2')
      successful_instance(res,Band['2'])
    end
  end

  describe 'DELETE /:model/:id' do
    it 'Sends not-found if the instance does not exist' do
      res = API.delete('/band/666')
      should_not_found(res)
    end
    it 'Returns a deletion response when the instance exists' do
      obj = Band['1']
      res = API.delete('/band/1')
      successful_deletion(res,obj)
    end
  end
end

