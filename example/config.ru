$:.unshift File.expand_path('../../lib', __FILE__)
# require 'populate_me'

# Models ##########

require 'populate_me/mongo'
require 'mongo'

MONGO = Mongo::Connection.new
DB    = MONGO['blog-populate-me-test']


class BlogPost
  include PopulateMe::Mongo
  field :title
  field :content, type: :text
  field :published, type: :boolean
  def authors; @authors ||= []; end
  def validate
    error_on(:content,'Cannot be blank') if PopulateMe::Utils.blank?(self.content)
  end
end
class BlogPost::Author
  include PopulateMe::Mongo
  field :name
end

# Admin ##########

require "populate_me/admin"
class Admin < PopulateMe::Admin
  enable :sessions
  set :menu, [ 
    ['Blog Posts', '/list/blog-post'],
  ]
end

run Admin

