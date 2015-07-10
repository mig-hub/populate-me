require 'bacon'
$:.unshift File.expand_path('../../lib', __FILE__)

require 'populate_me/admin'

class Admin < PopulateMe::Admin
  enable :sessions
  set :menu, [
    ['Home Details', '/admin/form/home-details/0'],
    ['Project Page', [
      ['Project Page Intro', '/admin/form/project-page-intro/0'],
      ['Projects', '/admin/list/project'],
      ['Checks', [
        ['Check 1', '/check/1'],
        ['Check 2', '/check/2']
      ]]
    ]]
  ]
end

class AdminNoSessions < PopulateMe::Admin
end

class AdminCerberusDisabled < PopulateMe::Admin
  disable :cerberus
end

REQ = Rack::MockRequest.new(Admin.new)

ENV['CERBERUS_PASS'] = '1234'
REQ_WITH_CERBERUS_PASS = Rack::MockRequest.new(Admin.new)
REQ_WITH_CERBERUS_PASS_NO_SESSIONS = Rack::MockRequest.new(AdminNoSessions.new)
REQ_WITH_CERBERUS_PASS_DISABLED = Rack::MockRequest.new(AdminCerberusDisabled.new)
ENV['CERBERUS_PASS'] = nil

describe 'PopulateMe::Admin' do

  describe 'Settings' do

    it 'Sets paths based on the subclass file path' do
      Admin.settings.app_file.should==__FILE__
    end

    it 'Has a default value for the page title tag' do
      Admin.settings.meta_title.should=='Populate Me'
    end

    it 'Has a default index_path' do
      Admin.settings.index_path.should=='/menu'
    end

    it 'Has logout_path disabled by default' do
      Admin.settings.logout_path?.should==false
    end

    it 'Has cerberus enabled by default' do
      Admin.settings.cerberus?.should==true
    end

  end

  describe 'Middlewares' do

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

    it 'Uses Cerberus (active) only if CERBERUS_PASS ENV variable is set as well' do
      res = REQ_WITH_CERBERUS_PASS.get('/')
      res.status.should==401
    end

    it 'Can disable Cerberus without removing CERBERUS_PASS ENV variable' do
      # Because you might want to mount it above in the rack stack
      res = REQ_WITH_CERBERUS_PASS_DISABLED.get('/')
      res.status.should==200
    end

    it 'Has no sessions by default even with Cerberus active' do
      lambda{ REQ_WITH_CERBERUS_PASS_NO_SESSIONS.get('/') }.should.raise(Rack::Cerberus::NoSessionError)
    end

  end

  describe 'Handlers' do

    it 'Can serve menu one level menu at a time' do
      # Level 0
      res = REQ.get('/menu')
      json = JSON.parse(res.body)
      res.content_type.should=='application/json'
      res.status.should==200
      json['template'].should=='template_menu'
      json['page_title'].should=='Menu'
      json['items'].should==[
        {'title'=> 'Home Details', 'href'=> '/admin/form/home-details/0'},
        {'title'=> 'Project Page', 'href'=> '/menu/project-page'}
      ]
      # Level 1
      res = REQ.get('/menu/project-page')
      json = JSON.parse(res.body)
      res.content_type.should=='application/json'
      res.status.should==200
      json['template'].should=='template_menu'
      json['page_title'].should=='Project Page'
      json['items'].should==[
        {'title'=> 'Project Page Intro',  'href'=> '/admin/form/project-page-intro/0'},
        {'title'=> 'Projects',  'href'=> '/admin/list/project'},
        {'title'=> 'Checks', 'href'=> '/menu/project-page/checks'}
      ]
      # Level 2
      res = REQ.get('/menu/project-page/checks')
      json = JSON.parse(res.body)
      res.content_type.should=='application/json'
      res.status.should==200
      json['template'].should=='template_menu'
      json['page_title'].should=='Checks'
      json['items'].should==[
        {'title'=> 'Check 1', 'href'=> '/check/1'},
        {'title'=> 'Check 2', 'href'=> '/check/2'}
      ]
    end

  end

end

