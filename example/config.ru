$:.unshift File.expand_path('../../lib', __FILE__)

# Models ##########

require 'populate_me/document'
require 'mongo'

MONGO = Mongo::Connection.new
DB    = MONGO['blog-populate-me-test']

# require 'populate_me/attachment'
# PopulateMe::Document.set :default_attachment_class, PopulateMe::Attachment
# require 'populate_me/file_system_attachment'
# PopulateMe::Document.set :default_attachment_class, PopulateMe::FileSystemAttachment
require 'populate_me/grid_fs_attachment'
PopulateMe::Document.set :default_attachment_class, PopulateMe::GridFS
PopulateMe::GridFS.set :db, DB

class BlogPost < PopulateMe::Document
  field :title, required: true
  field :thumbnail, type: :attachment, variations: [
    PopulateMe::Variation.new_image_magick_job(:populate_me_thumb, :jpg, "-resize '400x225^' -gravity center -extent 400x225")
  ]
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
  set :menu, [ 
    ['Blog Posts', '/list/blog-post'],
    ['Articles', '/list/article'],
  ]
end

# use PopulateMe::Attachment::Middleware
# use PopulateMe::FileSystemAttachment::Middleware
use PopulateMe::GridFS::Middleware
run Admin

