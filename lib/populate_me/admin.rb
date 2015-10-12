require 'populate_me/api'
require 'json'
require 'tilt/erb'
begin
  require "rack/cerberus"
rescue LoadError
  puts "Cerberus not loaded."
end

class PopulateMe::Admin < Sinatra::Base

  # Settings
  set :app_file, nil # Need to be set when subclassed
  set :show_exceptions, false
  set :meta_title, 'Populate Me'
  set :index_path, '/menu'
  enable :cerberus
  set :cerberus_active, Proc.new{
    Rack.const_defined?(:Cerberus) &&
    !!ENV['CERBERUS_PASS'] &&
    settings.cerberus?
  }
  set :logout_path, Proc.new{ settings.cerberus_active ? '/logout' : false }

  # Load API helpers
  helpers PopulateMe::API::Helpers
  helpers do
    def user_name
      return 'Anonymous' if session.nil?||session[:populate_me_user].nil?
      session[:populate_me_user]
    end
  end

  # Make all templates in admin/views accessible with their basename
  Dir["#{File.expand_path('../admin/views',__FILE__)}/*.erb"].each do |f|
    template File.basename(f,'.erb').to_sym do
      File.read(f)
    end
  end

  before do
    content_type :json
  end

  get '/?' do
    content_type :html
    erb :page, layout: false
  end

  get '/menu/?*?' do
    page_title = 'Menu'
    current_level = settings.menu.dup
    levels = params[:splat][0].split('/')
    levels.each do |l|
      page_title, current_level = current_level.find{|item| slugify(item[0])==l}
    end
    items = current_level.map do |l|
      href = l[1].is_a?(String) ? l[1] : "#{request.script_name}/menu#{levels.map{|l|'/'+l}.join}/#{slugify(l[0])}" 
      { title: l[0], href: href }
    end
    {
      template: 'template_menu',
      page_title: page_title,
      items: items
    }.to_json
  end

  get '/list/:class_name' do
    @model_class = resolve_model_class params[:class_name]
    @model_class.to_admin_list(request: request, params: params).to_json
  end

  get '/form/?:class_name?/?:id?' do
    @model_class = resolve_model_class params[:class_name]
    if params[:id].nil?
      @model_instance = @model_class.new.set_defaults
      @model_instance.set_from_hash(params[:data], typecast: true) unless params[:data].nil?
    else
      @model_instance = resolve_model_instance @model_class, params[:id]
    end
    @model_instance.to_admin_form(
      request: request, 
      params: params,
      nested: params[:nested]=='true', 
      input_name_prefix: params[:input_name_prefix]
    ).to_json
  end

  not_found do
    response.headers['X-Cascade'] = 'pass'
    {'success'=>false,'message'=>'Not Found'}.to_json
  end

  error do
    puts
    puts env['sinatra.error'].inspect
    puts
    {'success'=>false,'message'=>env['sinatra.error'].message}.to_json
  end

  class << self

    private

    def setup_default_middleware builder
      # Override the Sinatra method
      super builder
      setup_populate_me_middleware builder
    end

    def setup_populate_me_middleware builder
      # Authentication
      setup_cerberus builder
      # Mount assets on /__assets__
      builder.use Rack::Static, :urls=>['/__assets__'], :root=>File.expand_path('../admin',__FILE__)
      # Mount the API on /api
      builder.use Rack::Builder do 
        map('/api'){ run PopulateMe::API }
      end
    end

    def setup_cerberus builder
      return unless cerberus_active
      cerberus_settings = settings.cerberus==true ? {} : settings.cerberus
      cerberus_settings[:session_key] = 'populate_me_user'
      builder.use Rack::Cerberus, cerberus_settings do |user,pass,req|
        pass==ENV['CERBERUS_PASS']
      end
    end

  end

end

