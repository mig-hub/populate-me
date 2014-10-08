require 'bacon'
$:.unshift File.expand_path('../../lib', __FILE__)

require 'populate_me/document'
class Band
  include PopulateMe::Document
  attr_accessor :name, :awsome
  def members; @members ||= []; end
end
class Band::Member
  include PopulateMe::Document
  attr_accessor :name
end
Band.new(id: '1', name: 'Gang of Four').save
Band.new(id: '2', name: 'Autolux').save
ramones = Band.new(id: '3', name: 'Ramones')
ramones.members << Band::Member.new(name: 'Joey')
ramones.members << Band::Member.new(name: 'Deedee Ramone')
ramones.save

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
    json
  end
  
  def successful_creation(res)
    json = JSON.parse(res.body)
    res.content_type.should=='application/json'
    res.status.should==201
    json['success'].should==true
    json['message'].should=='Created Successfully'
    json
  end

  def successful_instance(res)
    json = JSON.parse(res.body)
    res.content_type.should=='application/json'
    res.status.should==200
    json['success'].should==true
    json
  end

  def successful_update(res)
    json = JSON.parse(res.body)
    res.content_type.should=='application/json'
    res.status.should==200
    json['success'].should==true
    json['message'].should=='Updated Successfully'
    json
  end

  def successful_deletion(res)
    json = JSON.parse(res.body)
    res.content_type.should=='application/json'
    res.status.should==200
    json['success'].should==true
    json['message'].should=='Deleted Successfully'
    json
  end

  describe 'GET /version' do
    it 'Returns the PopulateMe version' do
      res = API.get('/version')
      json = JSON.parse(res.body)
      res.content_type.should=='application/json'
      res.status.should==200
      json['success'].should==true
      json['version'].should==PopulateMe::VERSION
    end
  end

  describe 'POST /:model' do

    it 'Creates successfully' do
      res = API.post('/band', {params: {data: {id: '4', name: 'Neurosis'}}})
      json = successful_creation(res)
      json['data'].should==Band['4'].to_h
    end

    it 'Typecasts before creating' do
      res = API.post('/band', {params: {data: {name: 'Arcade Fire', awsome: 'true'}}})
      json = successful_creation(res)
      json['data']['awsome'].should==true
    end

    it 'Can create an doc even if no data is sent' do
      count = Band.documents.size
      res = API.post '/band'
      successful_creation(res)
      Band.documents.size.should==(count+1)
    end

    it 'Redirects if destination is given' do
      res = API.post '/band', {params: {'_destination'=>'http://example.org/anywhere'}}
      res.status.should==302
      res.header['Location'].should=='http://example.org/anywhere'
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
      json = successful_instance(res)
      json['data'].should==Band['2'].to_h
    end
  end

  describe 'PUT /:model/:id' do
    # it 'Sends not-found if the instance does not exist' do
    #   res = API.put('/band/666')
    #   should_not_found(res)
    # end
    # it 'Updates documents and embeded documents which are included' do
    #   obj = Band['3']
    #   res = API.put('/band/3', {params: {data: {awsome: 'yes'}}})
    #   successful_update(res)
    #   res = API.put('/band/3', {params: {data: {name: 'The Ramones'}}})
    #   successful_update(res)
    #   res = API.put('/band/3', {params: {data: {members: [{id: obj.members[0].id, name: 'Joey Ramone'}]}}})
    #   successful_update(res)
    #   obj = Band['3']
    #   obj.awsome.should=='yes'
    #   obj.name.should=='The Ramones'
    #   obj.members.size.should==2
    #   obj.members[0].name.should=='Joey Ramone'
    #   obj.members[1].name.should=='Deedee Ramone'
    # end
  end

  describe 'DELETE /:model/:id' do
    it 'Sends not-found if the instance does not exist' do
      res = API.delete('/band/666')
      should_not_found(res)
    end
    it 'Returns a deletion response when the instance exists' do
      obj = Band['1']
      res = API.delete('/band/1')
      json = successful_deletion(res)
      json['data'].should==obj.to_h
    end
    it 'Redirects if destination is given' do
      res = API.delete('/band/2', {params: {'_destination'=>'http://example.org/anywhere'}})
      res.status.should==302
      res.header['Location'].should=='http://example.org/anywhere'
    end
  end
end

