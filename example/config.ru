$:.unshift File.expand_path('../../lib', __FILE__)
# require 'populate_me'

# Models ##########

require 'populate_me/document'
require 'populate_me/attachment'
# require 'mongo'

# MONGO = Mongo::Connection.new
# DB    = MONGO['blog-populate-me-test']

PopulateMe::Document.set :default_attachment_class, PopulateMe::Attachment

class BlogPost < PopulateMe::Document
  field :title, required: true
  field :thumbnail, type: :attachment
  field :content, type: :text
  field :authors, type: :list
  field :published, type: :boolean
  relationship :comments
  def validate
    error_on(:content,'Cannot be blank') if PopulateMe::Utils.blank?(self.content)
  end
end
class BlogPost::Author < PopulateMe::Document
  # nested
  field :name
  def validate
    error_on(:name, 'Cannot be shit') if self.name=='shit'
  end
end
class BlogPost::Comment < PopulateMe::Document
  # not nested
  field :author, default: 'Anonymous'
  field :content, type: :text
  field :blog_post_id, type: :hidden
  position_field scope: :blog_post_id
end

class Article < PopulateMe::Document
  field :title
  field :content, type: :text
  position_field
end

# Admin ##########

require "populate_me/admin"
class Admin < PopulateMe::Admin
  enable :sessions
  set :menu, [ 
    ['Blog Posts', '/list/blog-post'],
    ['Articles', '/list/article'],
  ]
end

use PopulateMe::Attachment::Middleware
run Admin

