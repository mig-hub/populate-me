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

RSpec.describe PopulateMe::Admin do

  subject(:app) { Admin.new }

  let(:settings) { app.settings }
  let(:setenv_cerberus_pass) {
    allow(ENV).to receive(:[]).with('CERBERUS_PASS').and_return('123')
  }
  let(:cerberus_not_defined) {
    allow(Kernel).to receive(:const_defined?).with(:Cerberus).and_return(false)
  }
  let(:set_cerberus_active) {
    setenv_cerberus_pass
    allow(settings).to receive(:cerberus_active).and_return(true)
  }
  let(:set_cerberus_inactive) {
    allow(settings).to receive(:cerberus_active).and_return(false)
  }

  let(:json) { JSON.parse(last_response.body) }

  describe 'Settings' do
    it 'Sets paths based on the subclass file path' do
      expect(settings.app_file).to eq(__FILE__)
    end
    it 'Has a default value for the page title tag' do
      expect(settings.meta_title).to eq('Populate Me')
    end
    it 'Has a default index_path' do
      expect(settings.index_path).to eq('/menu')
    end
    it 'Has cerberus enabled by default' do
      expect(settings.cerberus?).to eq(true)
    end
    context 'when ENV CERBERUS_PASS is not set' do
      it 'Does not have cerberus_active' do
        expect(settings.cerberus_active).to eq(false)
      end
    end
    context 'when ENV CERBERUS_PASS is set' do
      it 'Has cerberus_active' do
        setenv_cerberus_pass
        expect(settings.cerberus_active).to eq(true)
      end
    end
    context 'when ENV CERBERUS_PASS is set but gem not loaded' do
      it 'Does not have cerberus_active' do
        setenv_cerberus_pass
        cerberus_not_defined
        expect(settings.cerberus_active).to eq(false)
      end
    end
    context 'when ENV CERBERUS_PASS is set but cerberus is disabled' do
      subject(:app) { AdminCerberusDisabled.new }
      it 'Does not have cerberus_active' do
        setenv_cerberus_pass
        expect(settings.cerberus_active).to eq(false)
      end
    end
    context 'when Cerberus is active' do
      it 'Sets logout_path to /logout' do
        set_cerberus_active
        expect(settings.logout_path).to eq('/logout')
      end
    end
    context 'when Cerberus is not active' do
      it 'Sets logout_path to false' do
        set_cerberus_inactive
        expect(settings.logout_path).to eq(false)
      end
    end
  end

  describe 'Middlewares' do

    it 'Has API middleware mounted on /api' do
      msg = 'API mounted'
      res = [200,{'Content-Type'=>'text/plain'},[msg]]
      allow_any_instance_of(PopulateMe::API).to receive(:call).and_return(res)
      get('/api')
      expect(last_response.body).to eq(msg)
    end

    it 'Has assets available on /__assets__' do
      get('/__assets__/css/main.css')
      expect(last_response).to be_ok
      expect(last_response.content_type).to eq('text/css')
    end

    context 'when cerberus is active' do
      it 'Uses Cerberus for authentication' do
        set_cerberus_active
        get '/'
        expect(last_response.status).to eq(401)
      end
    end
    context 'when cerberus is inactive' do
      it 'Does not use Cerberus' do
        set_cerberus_inactive
        get '/'
        expect(last_response).to be_ok
      end
    end

  end

  describe 'Handlers' do

    describe '/menu' do

      context 'when url is root' do
        it 'Returns the correct info' do
          get '/menu'
          expect(last_response).to be_json.and_ok
          expect(json).to be_for_view('template_menu').with_title('Menu')
          expect(json['items'].size).to eq(2)
          expect(json['items'][0]).to eq({
            'title'=> 'Home Details', 'href'=> '/admin/form/home-details/0'
          })
        end
      end
      context 'when url is nested' do
        it 'Returns the correct info' do
          get '/menu/project-page/checks' 
          expect(last_response).to be_json.and_ok
          expect(json).to be_for_view('template_menu').with_title('Checks')
          expect(json['items'].size).to eq(2)
          expect(json['items'][0]).to eq({
            'title'=> 'Check 1', 'href'=> '/check/1'
          })
        end
      end

    end

  end

end

