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
  set :menu, [ 
    ['Blog Posts', '/list/blog-post'],
  ]
end

run Admin

