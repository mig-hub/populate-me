require 'bacon'
$:.unshift File.expand_path('../../lib', __FILE__)

require 'populate_me/admin'

class Admin < PopulateMe::Admin
end

REQ = Rack::MockRequest.new(Admin.new)

describe 'PopulateMe::Admin' do

  it 'Sets paths based on the subclass file path' do
    Admin.settings.app_file.should==__FILE__
  end

  it 'Has API middleware mounted on /api' do
    res = REQ.get('/api/version')
    json = JSON.parse(res.body)
    res.content_type.should=='application/json'
    res.status.should==200
    json['success'].should==true
    json['version'].should==PopulateMe::VERSION
  end

  it 'Has assets available on /__assets__' do
    res = REQ.get('/__assets__/css/main.css')
    res.status.should==200
    res.content_type.should=='text/css'
  end

end

