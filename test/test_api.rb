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

  def must_be_not_found
    _(last_response).must_be_json
    _(last_response.status).must_equal 404
    _(last_response.headers['X-Cascade']).must_equal 'pass'
    _(json['success']).must_equal false
    _(json['message']).must_equal 'Not Found'
  end
  
  def must_be_successful_creation
    _(last_response).must_be_json
    _(last_response.status).must_equal 201
    _(json['success']).must_equal true
    _(json['message']).must_equal 'Created Successfully'
  end

  def must_be_successful_sorting
    _(last_response).must_be_json
    _(last_response).must_be :ok?
    _(json['success']).must_equal true
    _(json['message']).must_equal 'Sorted Successfully'
  end

  def must_be_invalid_instance
    _(last_response).must_be_json
    _(last_response.status).must_equal 400
    _(json['success']).must_equal false
    _(json['message']).must_equal 'Invalid Document'
  end

  def must_be_successful_instance
    _(last_response).must_be_json
    _(last_response).must_be :ok?
    _(json['success']).must_equal true
  end

  def must_be_successful_update
    _(last_response).must_be_json
    _(last_response).must_be :ok?
    _(json['success']).must_equal true
    _(json['message']).must_equal 'Updated Successfully'
  end

  def must_be_successful_deletion
    _(last_response).must_be_json
    _(last_response).must_be :ok?
    _(json['success']).must_equal true
    _(json['message']).must_equal 'Deleted Successfully'
  end

  describe 'GET /version' do
    it 'Returns the PopulateMe version' do
      get('/version')
      _(last_response).must_be_json
      _(last_response).must_be :ok?
      _(json['success']).must_equal true
      _(json['version']).must_equal PopulateMe::VERSION
    end
  end

  describe 'POST /:model' do

    it 'Creates successfully' do
      post('/band', {data: {id: 'neurosis', name: 'Neurosis'}})
      must_be_successful_creation
      _(json['data']['name']).must_equal 'Neurosis'
    end

    it 'Typecasts before creating' do
      post('/band', {data: {name: 'Arcade Fire', awsome: 'true'}})
      must_be_successful_creation
      _(json['data']['awsome']).must_equal true
    end

    it 'Can create a doc even if no data is sent' do
      post '/band'
      must_be_successful_creation
    end

    it 'Fails if the doc is invalid' do
      post('/band', {data: {id: 'invalid_doc_post', name: 'ZZ Top'}})
      must_be_invalid_instance
      _(json['data']).must_equal({'name'=>['WTF']})
      _(Band.admin_get('invalid_doc_post')).must_be_nil
    end

    it 'Redirects if destination is given' do
      post '/band', {'_destination'=>'http://example.org/anywhere'}
      _(last_response.status).must_equal 302
      _(last_response.header['Location']).must_equal 'http://example.org/anywhere'
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
      must_be_successful_sorting
      _(Band.admin_get('sortable2').position).must_equal 0
      _(Band.admin_get('sortable3').position).must_equal 1
      _(Band.admin_get('sortable1').position).must_equal 2
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
      _(last_response.status).must_equal 302
      _(last_response.header['Location']).must_equal 'http://example.org/anywhere'
    end

  end

  describe 'GET /:model/:id' do
    it 'Sends a not-found when the model is not a class' do
      get('/wizz/42')
      must_be_not_found
    end
    it 'Sends not-found when the model is a class but not a model' do
      get('/string/42')
      must_be_not_found
    end
    it 'Sends not-found when the id is not provided' do
      get('/band/')
      must_be_not_found
    end
    it 'Sends not-found when the instance does not exist' do
      get('/band/666')
      must_be_not_found
    end
    it 'Sends the instance if it exists' do
      post('/band', {data: {id: 'sendable', name: 'Morphine'}})
      get('/band/sendable')
      must_be_successful_instance
      _(json['data']).must_equal Band.admin_get('sendable').to_h
    end
  end

  describe 'PUT /:model/:id' do
    it 'Sends not-found if the instance does not exist' do
      put('/band/666')
      must_be_not_found
    end
    it 'Fails if the document is invalid' do
      post('/band', {data: {id: 'invalid_doc_put', name: 'Valid here'}})
      put('/band/invalid_doc_put', {data: {name: 'ZZ Top'}})
      must_be_invalid_instance
      _(json['data']).must_equal({'name'=>['WTF']})
      _(Band.admin_get('invalid_doc_put').name).wont_equal 'ZZ Top'
    end
    it 'Updates documents' do
      post('/band', {data: {id: 'updatable', name: 'Updatable'}})
      put('/band/updatable', {data: {awsome: 'yes'}})
      must_be_successful_update
      obj = Band.admin_get('updatable')
      _(obj.awsome).must_equal 'yes'
      _(obj.name).must_equal 'Updatable'
    end
    # it 'Updates nested documents' do
    #   obj = Band.admin_get('3')
    #   put('/band/3', {data: {members: [
    #     {id: obj.members[0].id, _class: 'Band::Member', name: 'Joey Ramone'},
    #     {id: obj.members[1].id, _class: 'Band::Member'},
    #   ]}})
    #   must_be_successful_update
    #   obj = Band.admin_get('3')
    #   _(obj.awsome).must_equal 'yes'
    #   _(obj.name).must_equal 'The Ramones'
    #   _(obj.members.size).must_equal 2
    #   _(obj.members[0].name).must_equal 'Joey Ramone'
    #   _(obj.members[1].name).must_equal 'Deedee Ramone'
    # end
  end

  describe 'DELETE /:model/:id' do
    it 'Sends not-found if the instance does not exist' do
      delete('/band/666')
      must_be_not_found
    end
    it 'Returns a deletion response when the instance exists' do
      post('/band', {data: {id: 'deletable', name: '1D'}})
      delete('/band/deletable')
      must_be_successful_deletion
      _(json['data']).must_be_instance_of Hash
    end
    it 'Redirects if destination is given' do
      delete('/band/2', {'_destination'=>'http://example.org/anywhere'})
      _(last_response.status).must_equal 302
      _(last_response.header['Location']).must_equal 'http://example.org/anywhere'
    end
  end
end

