require 'helper'
require 'populate_me/mongo'
require 'populate_me/grid_fs_attachment'

Mongo::Logger.logger.level = Logger::ERROR

GRIDMONGO = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'populate-me-grid-test')
GRIDDB = GRIDMONGO.database
GRIDDB.drop
PopulateMe::Mongo.set :db, GRIDDB
PopulateMe::Mongo.set :default_attachment_class, PopulateMe::GridFS
PopulateMe::GridFS.set :db, GRIDDB

describe 'PopulateMe::GridFS' do
  # parallelize_me!

  class GridBook < PopulateMe::Mongo
    field :cover, type: :attachment, variations: [
      PopulateMe::Variation.new_image_magick_job(:thumb, :gif, "-resize '300x'")
    ]
    field :content, type: :attachment, variations: [
      PopulateMe::Variation.new(:upcase, :txt, lambda{ |src,dst|
        Kernel.system "cat \"#{src}\" | tr 'a-z' 'A-Z' > \"#{dst}\""
      })
    ]
  end

  before do
    GRIDDB.drop
  end

  # Utils

  it 'Returns URL with attachee_prefix' do
    book = GridBook.new cover: "candy.jpg"
    assert_equal '/attachment/candy.jpg', book.attachment(:cover).url
    assert_equal '/attachment/candy.thumb.gif', book.attachment(:cover).url(:thumb)
  end

  it 'Has nil URL when field is blank' do
    book = GridBook.new
    assert_nil book.attachment(:cover).url
  end

  it 'Has location root without attachee prefix' do
    book = GridBook.new
    refute_match book.attachment(:cover).attachee_prefix, book.attachment(:cover).location_root
  end

  # Create

  it "Saves attachments on create with variations" do
    book = GridBook.new

    file = Tempfile.new('foo')
    file.write('hello')
    file.rewind

    assert_equal 0, GRIDDB['fs.files'].count
    field_value = book.attachment(:content).create({
      tempfile: file,
      filename: 'story.txt',
      type: 'text/plain'
    })
    assert_equal 2, GRIDDB['fs.files'].count
    assert_equal 'grid-book/story.txt', field_value

    gridfile = GRIDDB.fs.find(filename: 'grid-book/story.txt').first
    assert_equal 'text/plain', gridfile['contentType']
    assert_equal 'grid-book', gridfile['metadata']['parent_collection']
    GRIDDB.fs.open_download_stream(gridfile['_id']) do |stream|
      assert_equal 'hello', stream.read
    end

    vargridfile = GRIDDB.fs.find(filename: 'grid-book/story.upcase.txt').first
    assert_equal 'text/plain', vargridfile['contentType']
    assert_equal 'grid-book', vargridfile['metadata']['parent_collection']
    GRIDDB.fs.open_download_stream(vargridfile['_id']) do |stream|
      assert_equal 'HELLO', stream.read
    end

    file.close
    file.unlink
  end

  it 'Does not create 2 files with the same name' do
    file = Tempfile.new('foo')

    book = GridBook.new

    field_value = book.attachment(:content).create({
      tempfile: file,
      filename: 'story.txt',
      type: 'text/plain'
    })

    assert_equal 'grid-book/story.txt', field_value

    field_value = book.attachment(:content).create({
      tempfile: file,
      filename: 'story.txt',
      type: 'text/plain'
    })

    assert_equal 'grid-book/story-1.txt', field_value

    field_value = book.attachment(:content).create({
      tempfile: file,
      filename: 'story.txt',
      type: 'text/plain'
    })

    assert_equal 'grid-book/story-2.txt', field_value

    file.close
    file.unlink
  end

  # Delete

  it 'Is deletable when field is not blank' do
    book = GridBook.new cover: "candy.jpg"
    assert book.attachment(:cover).deletable?
  end

  it 'Is not deletable when field is blank' do
    book = GridBook.new
    refute book.attachment(:cover).deletable?
  end

  it 'Deletes all attachments' do
    file = Tempfile.new('foo')

    book = GridBook.new

    field_value = book.attachment(:content).create({
      tempfile: file,
      filename: 'story.txt',
      type: 'text/plain'
    })
    book.content = field_value

    refute_nil GRIDDB.fs.find(filename: 'grid-book/story.txt').first
    refute_nil GRIDDB.fs.find(filename: 'grid-book/story.upcase.txt').first

    book.attachment(:content).delete_all

    assert_nil GRIDDB.fs.find(filename: 'grid-book/story.txt').first
    assert_nil GRIDDB.fs.find(filename: 'grid-book/story.upcase.txt').first

    file.close
    file.unlink
  end

  it 'Deletes one attachment at a time' do
    file = Tempfile.new('foo')

    book = GridBook.new

    field_value = book.attachment(:content).create({
      tempfile: file,
      filename: 'story.txt',
      type: 'text/plain'
    })
    book.content = field_value

    refute_nil GRIDDB.fs.find(filename: 'grid-book/story.txt').first
    refute_nil GRIDDB.fs.find(filename: 'grid-book/story.upcase.txt').first

    book.attachment(:content).delete

    assert_nil GRIDDB.fs.find(filename: 'grid-book/story.txt').first
    refute_nil GRIDDB.fs.find(filename: 'grid-book/story.upcase.txt').first

    book.attachment(:content).delete :upcase

    assert_nil GRIDDB.fs.find(filename: 'grid-book/story.upcase.txt').first

    file.close
    file.unlink
  end

  # Update

  it 'Deletes previous attachment when saving a new one' do
    file = Tempfile.new('foo')
    file.write('hello')
    file.rewind

    book = GridBook.new

    field_value = book.attachment(:content).create({
      tempfile: file,
      filename: 'story.txt',
      type: 'text/plain'
    })
    book.content = field_value

    refute_nil GRIDDB.fs.find(filename: 'grid-book/story.txt').first
    refute_nil GRIDDB.fs.find(filename: 'grid-book/story.upcase.txt').first

    file.rewind
    file.write('world')
    file.rewind

    field_value = book.attachment(:content).create({
      tempfile: file,
      filename: 'history.md',
      type: 'text/markdown'
    })
    book.content = field_value

    assert_nil GRIDDB.fs.find(filename: 'grid-book/story.txt').first
    assert_nil GRIDDB.fs.find(filename: 'grid-book/story.upcase.txt').first
    refute_nil GRIDDB.fs.find(filename: 'grid-book/history.md').first
    refute_nil GRIDDB.fs.find(filename: 'grid-book/history.upcase.txt').first

    gridfile = GRIDDB.fs.find(filename: 'grid-book/history.md').first
    assert_equal 'text/markdown', gridfile['contentType']
    assert_equal 'grid-book', gridfile['metadata']['parent_collection']
    GRIDDB.fs.open_download_stream(gridfile['_id']) do |stream|
      assert_equal 'world', stream.read
    end

    gridfile = GRIDDB.fs.find(filename: 'grid-book/history.upcase.txt').first
    assert_equal 'text/plain', gridfile['contentType']
    assert_equal 'grid-book', gridfile['metadata']['parent_collection']
    GRIDDB.fs.open_download_stream(gridfile['_id']) do |stream|
      assert_equal 'WORLD', stream.read
    end

    file.close
    file.unlink
  end

end

GRIDDB.drop

