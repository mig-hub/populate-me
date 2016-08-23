require "populate_me/attachment"
require "mongo"
require "rack/gridfs"

module PopulateMe

  class MissingMongoDBError < StandardError; end

  class GridFSAttachment < Attachment

    set :url_prefix, '/attachment'

    def grid
      self.class.grid
    end

    def gridfs
      self.class.gridfs
    end

    def field_filename variation_name=nil
      return '' if Utils.blank?(self.field_value)
      return self.field_value if self.field_value.is_a?(String)
      raise 'PopulateMe::GridFS does not implement field_value that is not string yet'
    end

    def url variation_name=:original
      return nil if Utils.blank?(self.field_filename(variation_name))
      "#{settings.url_prefix.sub(/\/$/,'')}/#{self.field_filename(variation_name)}"
    end

    def deletable? variation_name=nil
      !Utils.blank? self.field_filename 
      # Fine since deleting a non-existent file does not raise an error in mongo
    end

    def perform_delete variation_name=nil
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
      fn = next_available_filename(hash[:filename])
      attachment_id = grid.put(
        hash[:tempfile], {
          filename: fn, 
          content_type: hash[:type],
          metadata: {
            parent_collection: self.document.class.collection.name,
          }
        }
      )
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

