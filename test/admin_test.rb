require 'bacon'
$:.unshift File.expand_path('../../lib', __FILE__)

require 'populate_me/admin'

class Admin < PopulateMe::Admin
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

