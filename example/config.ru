$:.unshift File.expand_path('../../lib', __FILE__)
require 'populate_me'

# Models ##########

require 'populate_me/document'
class BlogPost
  include PopulateMe::Document
  field :title
  field :content, type: :text
  field :published, type: :boolean
  def authors; @authors ||= []; end
end
class BlogPost::Author
  include PopulateMe::Document
  field :name
end

# Admin ##########

require "populate_me/admin"
class Admin < PopulateMe::Admin
  set :menu, [ ['Blog Posts', '/list/blog-post'] ]
  get '/' do
    redirect('/menu')
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

