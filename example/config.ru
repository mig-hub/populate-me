$:.unshift File.expand_path('../../lib', __FILE__)
require 'populate_me'

# Models ##########

require 'populate_me/document'
class BlogPost
  include PopulateMe::Document

end

# Rackup ##########

map '/api' do
  run PopulateMe::API
end

require "populate_me/admin"
class Admin < PopulateMe::Admin
  set :app_file, __FILE__
  set :menu, [ ['Blog Posts', '/list/blog-post'] ]
  get '/' do
    redirect('/')
  end
  get '/menu' do
    @menu = settings.menu
    erb :home, layout: !request.xhr?
  end
  get '/list/:model' do
    model_class = resolve_model_class(params[:model])
  end
end

map '/admin' do
  run Admin
end

