$:.unshift File.expand_path('../../lib', __FILE__)
require 'populate_me'

# Models ##########

require 'populate_me/document'
class BlogPost
  include PopulateMe::Document
  attr_accessor :title, :content, :published
  label :title
  def authors; @authors ||= []; end
end
class BlogPost::Author
  include PopulateMe::Document
  attr_accessor :name
end

# Admin ##########

require "populate_me/admin"
class Admin < PopulateMe::Admin
  # set :menu, [ ['Blog Posts', '/list/blog-post'] ]
  set :menu, [['Sub 1', [['Sub 1', '/admin/api/version'], ['Sub 2', '/admin/api/version']]]]
  get '/' do
    redirect('/admin/menu')
  end
  get '/list/:model' do
    @model_class = resolve_model_class(params[:model])
    @documents = @model_class.documents.map{|d| @model_class.from_hash(d) }
    erb :list, layout: !request.xhr?
  end
  get '/form/:model' do
    @model_class = resolve_model_class(params[:model])
    @model_instance = @model_class.new
    erb :form, layout: !request.xhr?
  end
end

run Admin

