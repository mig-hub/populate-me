require 'helper'
require 'populate_me/document'
require 'populate_me/s3_attachment'

s3_resource = Aws::S3::Resource.new
s3_bucket = s3_resource.bucket(ENV['BUCKET'])
PopulateMe::Document.set :default_attachment_class, PopulateMe::S3Attachment
PopulateMe::S3Attachment.set :bucket, s3_bucket

describe 'PopulateMe::S3Attachment' do
  # parallelize_me!

  def check_if_public_read(object)
    grant = object.acl.grants.find do |g|
      g.grantee.uri=="http://acs.amazonaws.com/groups/global/AllUsers"
    end
    raise "grant not found" if grant.nil?
    ['READ','FULL_CONTROL'].include? grant.permission
  end

  class S3Book < PopulateMe::Document
    field :cover, type: :attachment, variations: [
      PopulateMe::Variation.new_image_magick_job(:thumb, :gif, "-resize '300x'")
    ]
    field :content, type: :attachment, variations: [
      PopulateMe::Variation.new(:upcase, :txt, lambda{ |src,dst|
        Kernel.system "cat \"#{src}\" | tr 'a-z' 'A-Z' > \"#{dst}\""
      })
    ]
    field :open_content, type: :attachment, url_prefix: 'open', variations: [
      PopulateMe::Variation.new(:upcase, :txt, lambda{ |src,dst|
        Kernel.system "cat \"#{src}\" | tr 'a-z' 'A-Z' > \"#{dst}\""
      })
    ]
  end

  class S3BookNoPrefix < PopulateMe::Document
    set :s3_url_prefix, ''
    field :content, type: :attachment, variations: [
      PopulateMe::Variation.new(:upcase, :txt, lambda{ |src,dst|
        Kernel.system "cat \"#{src}\" | tr 'a-z' 'A-Z' > \"#{dst}\""
      })
    ]
  end

  before do
    s3_bucket.clear!
  end

  # Utils

  it 'Returns URL with bucket url' do
    book = S3Book.new cover: "candy.jpg"
    assert_equal "#{s3_bucket.url}/candy.jpg", book.attachment(:cover).url
    assert_equal "#{s3_bucket.url}/candy.thumb.gif", book.attachment(:cover).url(:thumb)
  end

  it 'Has nil URL when field is blank' do
    book = S3Book.new
    assert_nil book.attachment(:cover).url
  end

  it 'Has location root without attachee prefix' do
    book = S3Book.new
    refute_match book.attachment(:cover).attachee_prefix, book.attachment(:cover).location_root
  end

  # Create

  it "Saves attachments on create with variations" do
    book = S3Book.new

    file = Tempfile.new('foo')
    file.write('hello')
    file.rewind

    field_value = book.attachment(:content).create({
      tempfile: file,
      filename: 'story.txt',
      type: 'text/plain'
    })
    assert_equal 'public/s-3-book/story.txt', field_value
    assert s3_bucket.object('public/s-3-book/story.txt').exists? 
    assert s3_bucket.object('public/s-3-book/story.upcase.txt').exists? 

    s3file = s3_bucket.object('public/s-3-book/story.txt')
    assert_equal 'text/plain', s3file.content_type
    assert check_if_public_read(s3file)
    assert_equal 's-3-book', s3file.metadata['parent_collection']
    assert_equal 'hello', s3file.get.body.read

    vars3file = s3_bucket.object('public/s-3-book/story.upcase.txt')
    assert_equal 'text/plain', vars3file.content_type
    assert check_if_public_read(vars3file)
    assert_equal 's-3-book', vars3file.metadata['parent_collection']
    assert_equal 'HELLO', vars3file.get.body.read

    file.close
    file.unlink
  end

  it "Can override the url_prefix at document class level" do
    file = Tempfile.new('foo')
    book = S3BookNoPrefix.new

    field_value = book.attachment(:content).create({
      tempfile: file,
      filename: 'story.txt',
      type: 'text/plain'
    })

    assert_equal 's-3-book-no-prefix/story.txt', field_value
    assert s3_bucket.object('s-3-book-no-prefix/story.txt').exists? 
    assert s3_bucket.object('s-3-book-no-prefix/story.upcase.txt').exists? 
  end

  it "Can override the url_prefix at field level" do
    file = Tempfile.new('foo')
    book = S3Book.new

    field_value = book.attachment(:open_content).create({
      tempfile: file,
      filename: 'story.txt',
      type: 'text/plain'
    })

    assert_equal 'open/s-3-book/story.txt', field_value
    assert s3_bucket.object('open/s-3-book/story.txt').exists? 
    assert s3_bucket.object('open/s-3-book/story.upcase.txt').exists? 
  end

  it 'Does not create 2 files with the same name' do
    file = Tempfile.new('foo')

    book = S3Book.new

    field_value = book.attachment(:content).create({
      tempfile: file,
      filename: 'story.txt',
      type: 'text/plain'
    })

    assert_equal 'public/s-3-book/story.txt', field_value

    field_value = book.attachment(:content).create({
      tempfile: file,
      filename: 'story.txt',
      type: 'text/plain'
    })

    assert_equal 'public/s-3-book/story-1.txt', field_value

    field_value = book.attachment(:content).create({
      tempfile: file,
      filename: 'story.txt',
      type: 'text/plain'
    })

    assert_equal 'public/s-3-book/story-2.txt', field_value

    file.close
    file.unlink
  end

  # Delete

  it 'Is deletable when field is not blank' do
    book = S3Book.new cover: "candy.jpg"
    assert book.attachment(:cover).deletable?
  end

  it 'Is not deletable when field is blank' do
    book = S3Book.new
    refute book.attachment(:cover).deletable?
  end

  it 'Deletes all attachments' do
    file = Tempfile.new('foo')

    book = S3Book.new

    field_value = book.attachment(:content).create({
      tempfile: file,
      filename: 'story.txt',
      type: 'text/plain'
    })
    book.content = field_value

    assert s3_bucket.object('public/s-3-book/story.txt').exists? 
    assert s3_bucket.object('public/s-3-book/story.upcase.txt').exists? 

    book.attachment(:content).delete_all

    refute s3_bucket.object('public/s-3-book/story.txt').exists? 
    refute s3_bucket.object('public/s-3-book/story.upcase.txt').exists? 

    file.close
    file.unlink
  end

  it 'Deletes one attachment at a time' do
    file = Tempfile.new('foo')

    book = S3Book.new

    field_value = book.attachment(:content).create({
      tempfile: file,
      filename: 'story.txt',
      type: 'text/plain'
    })
    book.content = field_value

    assert s3_bucket.object('public/s-3-book/story.txt').exists? 
    assert s3_bucket.object('public/s-3-book/story.upcase.txt').exists? 

    book.attachment(:content).delete

    refute s3_bucket.object('public/s-3-book/story.txt').exists? 
    assert s3_bucket.object('public/s-3-book/story.upcase.txt').exists? 

    book.attachment(:content).delete :upcase

    refute s3_bucket.object('public/s-3-book/story.upcase.txt').exists? 

    file.close
    file.unlink
  end

  # Update

  it 'Deletes previous attachment when saving a new one' do
    file = Tempfile.new('foo')
    file.write('hello')
    file.rewind

    book = S3Book.new

    field_value = book.attachment(:content).create({
      tempfile: file,
      filename: 'story.txt',
      type: 'text/plain'
    })
    book.content = field_value

    assert s3_bucket.object('public/s-3-book/story.txt').exists? 
    assert s3_bucket.object('public/s-3-book/story.upcase.txt').exists? 

    file.rewind
    file.write('world')
    file.rewind

    field_value = book.attachment(:content).create({
      tempfile: file,
      filename: 'history.md',
      type: 'text/markdown'
    })
    book.content = field_value

    refute s3_bucket.object('public/s-3-book/story.txt').exists? 
    refute s3_bucket.object('public/s-3-book/story.upcase.txt').exists? 
    assert s3_bucket.object('public/s-3-book/history.md').exists? 
    assert s3_bucket.object('public/s-3-book/history.upcase.txt').exists? 

    s3file = s3_bucket.object('public/s-3-book/history.md')
    assert_equal 'text/markdown', s3file.content_type
    assert_equal 's-3-book', s3file.metadata['parent_collection']
    assert_equal 'world', s3file.get.body.read

    s3file = s3_bucket.object('public/s-3-book/history.upcase.txt')
    assert_equal 'text/plain', s3file.content_type
    assert_equal 's-3-book', s3file.metadata['parent_collection']
    assert_equal 'WORLD', s3file.get.body.read

    file.close
    file.unlink
  end

end

s3_bucket.clear!

