require 'populate_me/attachment'
require 'mongo'
require 'rack/gridfs'

module PopulateMe

  class MissingMongoDBError < StandardError; end

  class GridFSAttachment < Attachment

    # set :url_prefix, '/attachment'

    def grid
      self.class.grid
    end

    def gridfs
      self.class.gridfs
    end

    # Attachee_prefix is moved on field_value for gridfs
    def url variation_name=:original
      return nil if Utils.blank?(self.field_filename(variation_name))
      "#{settings.url_prefix.sub(/\/$/,'')}/#{self.field_filename(variation_name)}"
    end
    # Attachee_prefix is moved on field_value for gridfs
    def location_root
      File.join(
        settings.root, 
        settings.url_prefix
      )
    end

    def deletable? variation_name=:original
      !Utils.blank? self.field_filename(variation_name)
      # Fine since deleting a non-existent file does not raise an error in mongo
    end

    def perform_delete variation_name=:original
      # gridfs works with names instead of IDs
      gridfs.delete self.field_filename(variation_name)
    end

    def next_available_filename filename
      ext = File.extname(filename)
      base = "#{attachee_prefix}/#{File.basename(filename,ext)}"
      i = 0
      loop do
        suffix = i==0 ? '' : "-#{i}"
        potential_filename = [base,suffix,ext].join
        if grid.exist?(filename: potential_filename)
          i += 1
        else
          filename = potential_filename
          break
        end
      end
      filename
    end

    def perform_create hash
      if hash[:variation].nil?
        fn = next_available_filename(hash[:filename])
        file = hash[:tempfile]
        type = hash[:type]
      else
        fn = Utils.filename_variation hash[:future_field_value], hash[:variation].name, hash[:variation].ext
        file = File.open(hash[:variation_path])
        type = Rack::Mime.mime_type ".#{hash[:variation].ext}"
      end
      attachment_id = grid.put(
        file, {
          filename: fn, 
          content_type: type,
          metadata: {
            parent_collection: (self.document.class.respond_to?(:collection) ? self.document.class.collection.name : self.attachee_prefix),
          }
        }
      )
      file.close unless hash[:variation].nil?
      fn
    end

    class << self

      def ensure_db
        raise MissingMongoDBError, "Attachment class #{self.name} does not have a Mongo database." if settings.db.nil?
      end

      def grid
        ensure_db
        unless settings.grid.is_a?(::Mongo::Grid)
          set :grid, ::Mongo::Grid.new(settings.db) 
        end
        settings.grid
      end

      def gridfs
        ensure_db
        unless settings.gridfs.is_a?(::Mongo::GridFileSystem)
          set :gridfs, ::Mongo::GridFileSystem.new(settings.db) 
        end
        settings.gridfs
      end

      def middleware
        Rack::GridFS
      end

      def middleware_options
        [
          {
            prefix: settings.url_prefix.dup, 
            db: settings.db,
            lookup: :path
          }
        ]
      end

    end

  end

  GridFS = GridFSAttachment

end

