require 'bacon'
$:.unshift File.expand_path('../../lib', __FILE__)

require 'populate_me/document'
class Band < PopulateMe::Document
  attr_accessor :name, :awsome, :position
  def members; @members ||= []; end
  def validate
    error_on(:name,"WTF") if self.name=='ZZ Top'
  end
end
class Band::Member < PopulateMe::Document
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
  # - Class.admin_get
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

  def successful_sorting(res)
    json = JSON.parse(res.body)
    res.content_type.should=='application/json'
    res.status.should==200
    json['success'].should==true
    json['message'].should=='Sorted Successfully'
    json
  end

  def invalid_instance(res)
    json = JSON.parse(res.body)
    res.content_type.should=='application/json'
    res.status.should==400
    json['success'].should==false
    json['message'].should=='Invalid Document'
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
      json['data'].should==Band.admin_get('4').to_h
    end

    it 'Typecasts before creating' do
      res = API.post('/band', {params: {data: {name: 'Arcade Fire', awsome: 'true'}}})
      json = successful_creation(res)
      json['data']['awsome'].should==true
    end

    it 'Can create a doc even if no data is sent' do
      count = Band.documents.size
      res = API.post '/band'
      successful_creation(res)
      Band.documents.size.should==(count+1)
    end

    it 'Fails if the doc is invalid' do
      count = Band.documents.size
      res = API.post('/band', {params: {data: {name: 'ZZ Top'}}})
      json = invalid_instance(res)
      json['data'].should=={'name'=>['WTF']}
      Band.documents.size.should==count
    end

    it 'Redirects if destination is given' do
      res = API.post '/band', {params: {'_destination'=>'http://example.org/anywhere'}}
      res.status.should==302
      res.header['Location'].should=='http://example.org/anywhere'
    end

  end

  describe 'PUT /:model' do

    it 'Can set indexes for sorting' do
      res = API.put '/band', {
        params: {
          'action'=>'sort',
          'field'=>'position',
          'ids'=> ['2','3','1']
        }
      }
      json = successful_sorting(res)
      Band.admin_get('2').position.should==0
      Band.admin_get('3').position.should==1
      Band.admin_get('1').position.should==2
    end

    it 'Redirects after sorting if destination is given' do
      res = API.put '/band', {
        params: {
          'action'=>'sort',
          'field'=>'position',
          'ids'=> ['3','2','1'],
          '_destination'=>'http://example.org/anywhere'
        }
      }
      res.status.should==302
      res.header['Location'].should=='http://example.org/anywhere'
      Band.admin_get('3').position.should==0
      Band.admin_get('2').position.should==1
      Band.admin_get('1').position.should==2
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
      json['data'].should==Band.admin_get('2').to_h
    end
  end

  describe 'PUT /:model/:id' do
    it 'Sends not-found if the instance does not exist' do
      res = API.put('/band/666')
      should_not_found(res)
    end
    it 'Fails if the document is invalid' do
      res = API.put('/band/2', {params: {data: {name: 'ZZ Top'}}})
      json = invalid_instance(res)
      json['data'].should=={'name'=>['WTF']}
      Band.admin_get('2').name.should!='ZZ Top'
    end
    it 'Updates documents' do
      res = API.put('/band/3', {params: {data: {awsome: 'yes'}}})
      successful_update(res)
      res = API.put('/band/3', {params: {data: {name: 'The Ramones'}}})
      successful_update(res)
      obj = Band.admin_get('3')
      obj.awsome.should=='yes'
      obj.name.should=='The Ramones'
      obj.members.size.should==2
      obj.members[0].name.should=='Joey'
    end
    # it 'Updates nested documents' do
    #   obj = Band.admin_get('3')
    #   res = API.put('/band/3', {params: {data: {members: [
    #     {id: obj.members[0].id, _class: 'Band::Member', name: 'Joey Ramone'},
    #     {id: obj.members[1].id, _class: 'Band::Member'},
    #   ]}}})
    #   successful_update(res)
    #   obj = Band.admin_get('3')
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
      obj = Band.admin_get('1')
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

