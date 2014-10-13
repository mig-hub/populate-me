require 'populate_me/api'
require "json"

class PopulateMe::Admin < Sinatra::Base

  # Mount assets on /__assets__
  use Rack::Static, :urls=>['/__assets__'], :root=>File.expand_path('../admin',__FILE__)

  # Mount the API on /api
  use Rack::Builder do 
    map('/api'){ run PopulateMe::API }
  end

  # Reset :app_file so that it will be correct when class is inherited
  set :app_file, nil

  # Load API helpers
  helpers PopulateMe::API::Helpers
  helpers do
  end

  # Make all templates in admin/views accessible with their basename
  Dir["#{File.expand_path('../admin/views',__FILE__)}/*.erb"].each do |f|
    template File.basename(f,'.erb').to_sym do
      File.read(f)
    end
  end

  # Settings
  set :show_exceptions, false
  set :meta_title, 'Populate Me'
  set :index_path, '/menu'

  before do
    content_type :json
  end

  get '/' do
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
    @model_class = resolve_model_class(params[:class_name])
    @documents = @model_class.all # will need filter at some point
    items = @documents.map {|d| d.to_admin_list_item }
    {
      template: 'template_list',
      page_title: @model_class.to_s_plural,
      dasherized_class_name: params[:class_name],
      # 'sortable'=> @model_class.sortable_on_that_page?(@r),
      # 'command_plus'=> !@model_class.populate_config[:no_plus],
      # 'command_search'=> !@model_class.populate_config[:no_search],
      items: items,
    }.to_json
  end

  get '/form/:class_name' do
    @model_class = resolve_model_class(params[:class_name])
    @model_instance = @model_class.new
    content_type :html
    erb :form, layout: !request.xhr?
  end

  get '/form/:class_name/:id' do
    @model_class = resolve_model_class(params[:class_name])
    @model_instance = resolve_model_instance(@model_class,params[:id])
    content_type :html
    erb :form, layout: !request.xhr?
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

end

