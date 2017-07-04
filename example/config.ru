$:.unshift File.expand_path('../../lib', __FILE__)

# Models ##########

require 'populate_me/mongo'
require 'mongo'

MONGO = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'blog-populate-me-test')
DB    = MONGO.database
PopulateMe::Mongo.set :db, DB

# require 'populate_me/attachment'
# PopulateMe::Document.set :default_attachment_class, PopulateMe::Attachment
# require 'populate_me/file_system_attachment'
# PopulateMe::Document.set :default_attachment_class, PopulateMe::FileSystemAttachment
require 'populate_me/grid_fs_attachment'
PopulateMe::Mongo.set :default_attachment_class, PopulateMe::GridFS
PopulateMe::GridFS.set :db, DB

class BlogPost < PopulateMe::Mongo
  field :title, required: true
  field :thumbnail, type: :attachment, variations: [
    PopulateMe::Variation.new_image_magick_job(:populate_me_thumb, :jpg, "-resize '400x225^' -gravity center -extent 400x225")
  ]
  field :content, type: :text
  field :authors, type: :list
  field :published, type: :boolean
  relationship :comments
  def validate
    error_on(:content,'Cannot be blank') if WebUtils.blank?(self.content)
  end
end
class BlogPost::Author < PopulateMe::Mongo
  # nested
  field :name
  def validate
    error_on(:name, 'Cannot be shit') if self.name=='shit'
  end
end
class BlogPost::Comment < PopulateMe::Mongo
  # not nested
  field :author, default: 'Anonymous'
  field :content, type: :text
  field :blog_post_id, type: :hidden
  position_field scope: :blog_post_id
end

class Article < PopulateMe::Mongo
  field :title
  field :content, type: :text
  position_field
end

# Admin ##########

require "populate_me/admin"
class Admin < PopulateMe::Admin
  set :menu, [ 
    ['Blog Posts', '/list/blog-post'],
    ['Articles', '/list/article'],
  ]
end

# use PopulateMe::Attachment::Middleware
# use PopulateMe::FileSystemAttachment::Middleware
use PopulateMe::GridFS::Middleware
run Admin

