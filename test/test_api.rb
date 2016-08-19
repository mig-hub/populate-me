require 'helper'

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

require 'populate_me/api'

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

  parallelize_me!

  let(:app) {
    PopulateMe::API.new
  }

  let(:json) {
    JSON.parse(last_response.body)
  }

  def assert_not_found
    assert_json last_response
    assert_equal 404, last_response.status
    assert_equal 'pass', last_response.headers['X-Cascade']
    refute json['success']
    assert_equal 'Not Found', json['message']
  end
  
  def assert_successful_creation
    assert_json last_response
    assert_equal 201, last_response.status
    assert json['success']
    assert_equal 'Created Successfully', json['message']
  end

  def assert_successful_sorting
    assert_json last_response
    assert_predicate last_response, :ok?
    assert json['success']
    assert_equal 'Sorted Successfully', json['message']
  end

  def assert_invalid_instance
    assert_json last_response
    assert_equal 400, last_response.status
    refute json['success']
    assert_equal 'Invalid Document', json['message']
  end

  def assert_successful_instance
    assert_json last_response
    assert_predicate last_response, :ok?
    assert json['success']
  end

  def assert_successful_update
    assert_json last_response
    assert_predicate last_response, :ok?
    assert json['success']
    assert_equal 'Updated Successfully', json['message']
  end

  def assert_successful_deletion
    assert_json last_response
    assert_predicate last_response, :ok?
    assert json['success']
    assert_equal 'Deleted Successfully', json['message']
  end

  describe 'GET /version' do
    it 'Returns the PopulateMe version' do
      get('/version')
      assert_json last_response
      assert_predicate last_response, :ok?
      assert json['success']
      assert_equal PopulateMe::VERSION, json['version']
    end
  end

  describe 'POST /:model' do

    it 'Creates successfully' do
      post('/band', {data: {id: 'neurosis', name: 'Neurosis'}})
      assert_successful_creation
      assert_equal 'Neurosis', json['data']['name']
    end

    it 'Typecasts before creating' do
      post('/band', {data: {name: 'Arcade Fire', awsome: 'true'}})
      assert_successful_creation
      assert json['data']['awsome']
    end

    it 'Can create a doc even if no data is sent' do
      post '/band'
      assert_successful_creation
    end

    it 'Fails if the doc is invalid' do
      post('/band', {data: {id: 'invalid_doc_post', name: 'ZZ Top'}})
      assert_invalid_instance
      assert_equal({'name'=>['WTF']}, json['data'])
      assert_nil Band.admin_get('invalid_doc_post')
    end

    it 'Redirects if destination is given' do
      post '/band', {'_destination'=>'http://example.org/anywhere'}
      assert_equal 302, last_response.status
      assert_equal 'http://example.org/anywhere', last_response.header['Location']
    end

  end

  describe 'PUT /:model' do

    it 'Can set indexes for sorting' do
      post('/band', {data: {id: 'sortable1', name: 'Sortable 1'}})
      post('/band', {data: {id: 'sortable2', name: 'Sortable 2'}})
      post('/band', {data: {id: 'sortable3', name: 'Sortable 3'}})
      put '/band', {
        'action'=>'sort',
        'field'=>'position',
        'ids'=> ['sortable2','sortable3','sortable1']
      }
      assert_successful_sorting
      assert_equal 0, Band.admin_get('sortable2').position
      assert_equal 1, Band.admin_get('sortable3').position
      assert_equal 2, Band.admin_get('sortable1').position
    end

    it 'Redirects after sorting if destination is given' do
      post('/band', {data: {id: 'redirectsortable1', name: 'Redirect Sortable 1'}})
      post('/band', {data: {id: 'redirectsortable2', name: 'Redirect Sortable 2'}})
      post('/band', {data: {id: 'redirectsortable3', name: 'Redirect Sortable 3'}})
      put '/band', {
        'action'=>'sort',
        'field'=>'position',
        'ids'=> ['redirectsortable2','redirectsortable3','redirectsortable1'],
        '_destination'=>'http://example.org/anywhere'
      }
      assert_equal 302, last_response.status
      assert_equal 'http://example.org/anywhere', last_response.header['Location']
    end

  end

  describe 'GET /:model/:id' do
    it 'Sends a not-found when the model is not a class' do
      get('/wizz/42')
      assert_not_found
    end
    it 'Sends not-found when the model is a class but not a model' do
      get('/string/42')
      assert_not_found
    end
    it 'Sends not-found when the id is not provided' do
      get('/band/')
      assert_not_found
    end
    it 'Sends not-found when the instance does not exist' do
      get('/band/666')
      assert_not_found
    end
    it 'Sends the instance if it exists' do
      post('/band', {data: {id: 'sendable', name: 'Morphine'}})
      get('/band/sendable')
      assert_successful_instance
      assert_equal Band.admin_get('sendable').to_h, json['data']
    end
  end

  describe 'PUT /:model/:id' do
    it 'Sends not-found if the instance does not exist' do
      put('/band/666')
      assert_not_found
    end
    it 'Fails if the document is invalid' do
      post('/band', {data: {id: 'invalid_doc_put', name: 'Valid here'}})
      put('/band/invalid_doc_put', {data: {name: 'ZZ Top'}})
      assert_invalid_instance
      assert_equal({'name'=>['WTF']}, json['data'])
      refute_equal 'ZZ Top', Band.admin_get('invalid_doc_put').name
    end
    it 'Updates documents' do
      post('/band', {data: {id: 'updatable', name: 'Updatable'}})
      put('/band/updatable', {data: {awsome: 'yes'}})
      assert_successful_update
      obj = Band.admin_get('updatable')
      assert_equal 'yes', obj.awsome
      assert_equal 'Updatable', obj.name
    end
    # it 'Updates nested documents' do
    #   obj = Band.admin_get('3')
    #   put('/band/3', {data: {members: [
    #     {id: obj.members[0].id, _class: 'Band::Member', name: 'Joey Ramone'},
    #     {id: obj.members[1].id, _class: 'Band::Member'},
    #   ]}})
    #   assert_successful_update
    #   obj = Band.admin_get('3')
    #   assert_equal 'yes', obj.awsome
    #   assert_equal 'The Ramones', obj.name
    #   assert_equal 2, obj.members.size
    #   assert_equal 'Joey Ramone', obj.members[0].name
    #   assert_equal 'Deedee Ramone', obj.members[1].name
    # end
  end

  describe 'DELETE /:model/:id' do
    it 'Sends not-found if the instance does not exist' do
      delete('/band/666')
      assert_not_found
    end
    it 'Returns a deletion response when the instance exists' do
      post('/band', {data: {id: 'deletable', name: '1D'}})
      delete('/band/deletable')
      assert_successful_deletion
      assert_instance_of Hash, json['data']
    end
    it 'Redirects if destination is given' do
      delete('/band/2', {'_destination'=>'http://example.org/anywhere'})
      assert_equal 302, last_response.status
      assert_equal 'http://example.org/anywhere', last_response.header['Location']
    end
  end
end

