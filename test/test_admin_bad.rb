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

class AdminCerberusDisabled < PopulateMe::Admin
  disable :cerberus
end

describe PopulateMe::Admin do

  # parallelize_me!

  let(:app) { Admin.new }

  let(:settings) { app.settings }

  def setenv_cerberus_pass
    ENV.stub(:[], '123', ['CERBERUS_PASS']) { yield }
    # old = ENV['CERBERUS_PASS']
    # ENV['CERBERUS_PASS'] = '123'
    # yield
    # ENV['CERBERUS_PASS'] = old
  end

  def unsetenv_cerberus_pass
    # ENV.stub(:[], nil, ['CERBERUS_PASS']) { yield }
    old = ENV['CERBERUS_PASS']
    ENV['CERBERUS_PASS'] = nil
    yield
    ENV['CERBERUS_PASS'] = old
  end

  def cerberus_not_defined
    Rack.stub(:const_defined?, false, [:Cerberus]) { yield }
  end

  def set_cerberus_active
    setenv_cerberus_pass do
      # settings.stub(:cerberus_active, true) { yield }
      old = settings.cerberus
      settings.cerberus = true
      yield
      settings.cerberus = old
    end
  end

  def set_cerberus_inactive
    # settings.stub(:cerberus_active, false) { yield }
    old = settings.cerberus
    settings.cerberus = false
    yield
    settings.cerberus = old
  end

  let(:json) { JSON.parse(last_response.body) }

  describe 'Settings' do
    it 'Sets paths based on the subclass file path' do
      _(settings.app_file).must_equal(__FILE__)
    end
    it 'Has a default value for the page title tag' do
      _(settings.meta_title).must_equal('Populate Me')
    end
    it 'Has a default index_path' do
      _(settings.index_path).must_equal('/menu')
    end
    it 'Has cerberus enabled by default' do
      _(settings.cerberus?).must_equal(true)
    end
    describe 'when ENV CERBERUS_PASS is not set' do
      it 'Does not have cerberus_active' do
        unsetenv_cerberus_pass do
          _(settings.cerberus_active).must_equal(false)
        end
      end
    end
    describe 'when ENV CERBERUS_PASS is set' do
      it 'Has cerberus_active' do
        setenv_cerberus_pass do
          _(settings.cerberus_active).must_equal(true)
        end
      end
    end
    describe 'when ENV CERBERUS_PASS is set but gem not loaded' do
      it 'Does not have cerberus_active' do
        setenv_cerberus_pass do
          cerberus_not_defined do
            _(settings.cerberus_active).must_equal(false)
          end
        end
      end
    end
    describe 'when ENV CERBERUS_PASS is set but cerberus is disabled' do
      let(:app) { AdminCerberusDisabled.new }
      it 'Does not have cerberus_active' do
        setenv_cerberus_pass do
          _(settings.cerberus_active).must_equal(false)
        end
      end
    end
    describe 'when Cerberus is active' do
      it 'Sets logout_path to /logout' do
        # set_cerberus_active do
        setenv_cerberus_pass do
          _(settings.logout_path).must_equal('/logout')
        end
      end
    end
    describe 'when Cerberus is not active' do
      it 'Sets logout_path to false' do
        # set_cerberus_inactive do
        unsetenv_cerberus_pass do
          _(settings.logout_path).must_equal(false)
        end
      end
    end
  end

  describe 'Middlewares' do

    it 'Has API middleware mounted on /api' do
      msg = 'API mounted'
      res = [200,{'Content-Type'=>'text/plain'},[msg]]
      PopulateMe::API.stub_any_instance(:call, res) do
        get('/api')
        _(last_response.body).must_equal(msg)
      end
    end

    it 'Has assets available on /__assets__' do
      get('/__assets__/css/main.css')
      _(last_response).must_be :ok?
      _(last_response.content_type).must_equal('text/css')
    end

    describe 'when cerberus is active' do
      it 'Uses Cerberus for authentication' do
        # set_cerberus_active do
        setenv_cerberus_pass do
          get '/'
          _(last_response.status).must_equal(401)
        end
      end
    end
    describe 'when cerberus is inactive' do
      it 'Does not use Cerberus' do
        # set_cerberus_inactive do
        unsetenv_cerberus_pass do
          get '/'
          _(last_response).must_be :ok?
        end
      end
    end

  end

  describe 'Handlers' do

    describe '/menu' do

      describe 'when url is root' do
        it 'Returns the correct info' do
          get '/menu'
          _(last_response).must_be :ok?
          _(last_response).must_be_json
          _(json).must_be_for_view('template_menu','Menu')
          _(json['items'].size).must_equal(2)
          _(json['items'][0]).must_equal({
            'title'=> 'Home Details', 'href'=> '/admin/form/home-details/0'
          })
        end
      end
      describe 'when url is nested' do
        it 'Returns the correct info' do
          get '/menu/project-page/checks' 
          _(last_response).must_be :ok?
          _(last_response).must_be_json
          _(json).must_be_for_view('template_menu','Checks')
          _(json['items'].size).must_equal(2)
          _(json['items'][0]).must_equal({
            'title'=> 'Check 1', 'href'=> '/check/1'
          })
        end
      end

    end

  end

end

