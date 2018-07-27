# We use this example for running real tests on top of unit tests.
# This is not meant to be an example to learn how PopulateMe would work.
# Real examples will come later and this file will be removed.

$:.unshift File.expand_path('../../lib', __FILE__)

# Models ##########

require 'populate_me/document'

# MONGO = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'blog-populate-me-test')
# DB    = MONGO.database
# PopulateMe::Mongo.set :db, DB

require 'populate_me/attachment'
PopulateMe::Document.set :default_attachment_class, PopulateMe::Attachment
# require 'populate_me/file_system_attachment'
# PopulateMe::Document.set :default_attachment_class, PopulateMe::FileSystemAttachment
#
# require 'populate_me/grid_fs_attachment'
# PopulateMe::Mongo.set :default_attachment_class, PopulateMe::GridFS
# PopulateMe::GridFS.set :db, DB

# require 'populate_me/s3_attachment'
# s3_resource = Aws::S3::Resource.new
# s3_bucket = s3_resource.bucket(ENV['BUCKET'])
# PopulateMe::Document.set :default_attachment_class, PopulateMe::S3Attachment
# PopulateMe::S3Attachment.set :bucket, s3_bucket


class BlogPost < PopulateMe::Document
  field :title, required: true
  field :thumbnail, type: :attachment, max_size: 600*1024, variations: [
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
  field :yes_or_no, type: :select, select_options: [:yes,:no]
  field :tags, type: :select, multiple: true, select_options: ['art','sport','science']
  field :price, type: :price
  position_field

  relationship :sections

  after :save do
    puts self.inspect
  end
end

class Article::Section < PopulateMe::Document

  field :short, only_for: 'Nice Short'
  field :long, only_for: 'Nice Long'
  field :article_id, type: :hidden
  position_field scope: :article_id

end

# Admin ##########

require "populate_me/admin"
class Admin < PopulateMe::Admin
  set :menu, [ 
    ['Blog Posts', '/list/blog-post'],
    ['Articles', '/list/article'],
  ]
end

use PopulateMe::Attachment::Middleware
# use PopulateMe::FileSystemAttachment::Middleware
# use PopulateMe::GridFS::Middleware
run Admin

