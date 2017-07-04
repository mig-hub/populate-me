require 'populate_me/attachment'
require 'mongo'
require 'rack/grid_serve'

module PopulateMe

  class MissingMongoDBError < StandardError; end

  class GridFSAttachment < Attachment

    # set :url_prefix, '/attachment'

    # Attachee_prefix is moved on field_value for gridfs
    def url variation_name=:original
      return nil if WebUtils.blank?(self.field_filename(variation_name))
      "#{settings.url_prefix.sub(/\/$/,'')}/#{self.field_filename(variation_name)}"
    end
    # Attachee_prefix is moved on field_value for gridfs
    def location_root
      File.join(
        settings.root, 
        settings.url_prefix
      )
    end

    def next_available_filename filename
      ext = File.extname(filename)
      base = "#{attachee_prefix}/#{File.basename(filename,ext)}"
      i = 0
      loop do
        suffix = i==0 ? '' : "-#{i}"
        potential_filename = [base,suffix,ext].join
        if settings.db.fs.find(filename: potential_filename).count>0
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
        fn = WebUtils.filename_variation hash[:future_field_value], hash[:variation].name, hash[:variation].ext
        file = File.open(hash[:variation_path])
        type = Rack::Mime.mime_type ".#{hash[:variation].ext}"
      end
      settings.db.fs.upload_from_stream(
        fn,
        file, {
          content_type: type,
          metadata: {
            parent_collection: (self.document.class.respond_to?(:collection) ? self.document.class.collection.name : self.attachee_prefix),
          }
        }
      )
      file.close unless hash[:variation].nil?
      fn
    end

    def deletable? variation_name=:original
      !WebUtils.blank? self.field_filename(variation_name)
      # Fine since deleting a non-existent file does not raise an error in mongo
    end

    def perform_delete variation_name=:original
      gridfile = settings.db.fs.find(filename: self.field_filename(variation_name)).first
      settings.db.fs.delete(gridfile['_id']) unless gridfile.nil?
    end

    class << self

      def ensure_db
        raise MissingMongoDBError, "Attachment class #{self.name} does not have a Mongo database." if settings.db.nil?
      end

      def middleware
        Rack::GridServe
      end

      def middleware_options
        [
          {
            prefix: settings.url_prefix.dup.gsub(/^\/|\/$/,''), 
            db: settings.db,
            # lookup: :path
          }
        ]
      end

    end

  end

  GridFS = GridFSAttachment

end

