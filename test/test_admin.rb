require 'helper'
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

class AdminWithCerberusPass < Admin
  def self.cerberus_pass
    '123'
  end
end

class AdminWithCustomCerberusAuth < AdminWithCerberusPass
  def self.cerberus_auth user, pass, req
    [user, pass] == ['mario', '1234']
  end
end

class AdminCerberusNotAvailable < AdminWithCerberusPass
  def self.cerberus_available?
    false
  end
end

class AdminCerberusDisabled < AdminWithCerberusPass
  disable :cerberus
end

describe PopulateMe::Admin do

  parallelize_me!

  let(:app) { ::Admin.new }

  let(:settings) { app.settings }

  let(:json) { JSON.parse(last_response.body) }

  describe 'Settings' do
    it 'Sets paths based on the subclass file path' do
      assert_equal __FILE__, settings.app_file
    end
    it 'Has a default value for the page title tag' do
      assert_equal 'Populate Me', settings.meta_title
    end
    it 'Has a default index_path' do
      assert_equal '/menu', settings.index_path
    end
    it 'Has cerberus enabled by default' do
      assert settings.cerberus?
    end
    describe 'when ENV CERBERUS_PASS is not set' do
      it 'Does not have cerberus_active' do
        refute settings.cerberus_active
      end
    end
    describe 'when ENV CERBERUS_PASS is set' do
      let(:app) { AdminWithCerberusPass.new }
      it 'Has cerberus_active' do
        assert settings.cerberus_active
      end
    end
    describe 'when ENV CERBERUS_PASS is set but gem not loaded' do
      let(:app) { AdminCerberusNotAvailable.new }
      it 'Does not have cerberus_active' do
        refute settings.cerberus_active
      end
    end
    describe 'when ENV CERBERUS_PASS is set but cerberus is disabled' do
      let(:app) { AdminCerberusDisabled.new }
      it 'Does not have cerberus_active' do
        refute settings.cerberus_active
      end
    end
    describe 'when Cerberus is active' do
      let(:app) { AdminWithCerberusPass.new }
      it 'Sets logout_path to /logout' do
        assert_equal '/logout', settings.logout_path
      end
    end
    describe 'when Cerberus is not active' do
      it 'Sets logout_path to false' do
        refute settings.logout_path
      end
    end
  end

  describe 'Middlewares' do

    it 'Has API middleware mounted on /api' do
      get '/api'
      assert_predicate last_response, :ok?
      assert_json last_response
      assert json['success']
    end

    it 'Has assets available on /__assets__' do
      get('/__assets__/css/main.css')
      assert_predicate last_response, :ok?
      assert_equal 'text/css', last_response.content_type
    end

    describe 'When cerberus is active' do
      let(:app) { AdminWithCerberusPass.new }
      it 'Uses Cerberus for authentication' do
        get '/'
        assert_equal 401, last_response.status
      end
      it 'Authenticates with right login details' do
        get '/', {
          cerberus_login: 'admin',
          cerberus_pass: '123',
          _method: 'get'
        }
        assert_equal 200, last_response.status
      end
      it 'Fails authentication when login details are wrong' do
        get '/', {
          cerberus_login: 'admin',
          cerberus_pass: 'xxx',
          _method: 'get'
        }
        assert_equal 401, last_response.status
      end
    end
    describe 'When cerberus is inactive' do
      it 'Does not use Cerberus' do
        get '/'
        assert_predicate last_response, :ok?
      end
    end
    describe 'When cerberus_auth is overridden' do
      let(:app) { AdminWithCustomCerberusAuth.new }
      it 'Authenticates with right login details' do
        get '/', {
          cerberus_login: 'mario',
          cerberus_pass: '1234',
          _method: 'get'
        }
        assert_equal 200, last_response.status
      end
      it 'Fails authentication when login details are wrong' do
        get '/', {
          cerberus_login: 'admin',
          cerberus_pass: '123',
          _method: 'get'
        }
        assert_equal 401, last_response.status
      end
    end

  end

  describe 'Handlers' do

    let(:help_item) {
      { 'title' => '?', 'href' => '/help', 'new_page' => false }
    }

    describe '/menu' do

      describe 'when url is root' do
        it 'Returns the correct info' do
          get '/menu'
          assert_predicate last_response, :ok?
          assert_json last_response
          assert_for_view json, 'template_menu', 'Menu'
          expected_h = {
            'title' => 'Home Details', 
            'href' => '/admin/form/home-details/0', 
            'new_page' => false
          }
          assert_equal expected_h, json['items'][0]
          expected_h = {
            'title' => 'Project Page', 
            'href' => '/menu/project-page',
            'new_page' => false
          }
          assert_equal expected_h, json['items'][1]
        end
        it 'Adds help link' do
          get '/menu'
          assert_equal 3, json['items'].size
          assert_equal(help_item, json['items'].last)
        end
      end
      describe 'when url is nested' do
        it 'Returns the correct info' do
          get '/menu/project-page/checks' 
          assert_predicate last_response, :ok?
          assert_json last_response
          assert_for_view json, 'template_menu', 'Checks'
          assert_equal 2, json['items'].size
          expected_h = {
            'title' => 'Check 1', 
            'href' => '/check/1', 
            'new_page' => false
          }
          assert_equal expected_h, json['items'][0]
        end
        it 'Does not add help link' do
          get '/menu/project-page/checks'
          refute_equal(help_item, json['items'].last)
        end
      end

    end

  end

end

