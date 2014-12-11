$:.unshift File.expand_path('../../lib', __FILE__)
# require 'populate_me'

# Models ##########

require 'populate_me/mongo'
require 'mongo'

MONGO = Mongo::Connection.new
DB    = MONGO['blog-populate-me-test']


class BlogPost
  include PopulateMe::Document
  field :title, required: true
  field :content, type: :text
  field :authors, type: :list
  field :published, type: :boolean
  relationship :comments
  def validate
    # error_on(:content,'Cannot be blank') if PopulateMe::Utils.blank?(self.content)
  end
end
class BlogPost::Author
  # embeded
  include PopulateMe::Document
  field :name
end
class BlogPost::Comment
  # not embeded
  include PopulateMe::Document 
  field :author, default: 'Anonymous'
  field :content, type: :text
  field :blog_post_id, type: :hidden
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

