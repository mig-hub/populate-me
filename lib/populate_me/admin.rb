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

  before do
    @meta_title = "Populate Me"
  end
  get '/' do
    # redirect('/menu')
    erb ""
  end
  get '/menu/?*?' do
    @level_menu = settings.menu.dup
    @levels = params[:splat].reject{|s|blank?(s)}
    @levels.each do |l|
      @level_menu = @level_menu.find{|item| slugify(item[0])==l}[1]
    end
    @level_menu.map! do |l|
      href = l[1].is_a?(String) ? l[1] : "#{request.script_name}/menu#{@levels.map{|l|'/'+l}.join}/#{slugify(l[0])}" 
      {
        title: l[0],
        href: href
      }
    end
    # erb :menu, layout: !request.xhr?
    content_type :json
    {
      action: 'menu',
      page_title: 'Menu',
      items: @level_menu
    }.to_json
  end
  get '/list/:class_name' do
    @model_class = resolve_model_class(params[:class_name])
    @documents = @model_class.all
    erb :list, layout: !request.xhr?
  end
  get '/form/:class_name' do
    @model_class = resolve_model_class(params[:class_name])
    @model_instance = @model_class.new
    erb :form, layout: !request.xhr?
  end
  get '/form/:class_name/:id' do
    @model_class = resolve_model_class(params[:class_name])
    @model_instance = resolve_model_instance(@model_class,params[:id])
    erb :form, layout: !request.xhr?
  end
end

