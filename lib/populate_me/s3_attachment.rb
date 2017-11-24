require 'populate_me/attachment'
require 'aws-sdk'

module PopulateMe

  class MissingBucketError < StandardError; end

  class S3Attachment < Attachment

    # For S3 this option behaves a bit differently.
    # Because S3 file are served directly instead of using a middleware,
    # the url_prefix is just used in the key name before the attachee_prefix.
    # It helps saving keys under /public for example which is a common idiom
    # to save file in a path public by default.
    # This option can be overriden at the field level.
    set :url_prefix, '/public'

    # Attachee_prefix is moved on field_value for S3
    # as well as url_prefix
    def url variation_name=:original
      return nil if WebUtils.blank?(self.field_filename(variation_name))
      "#{settings.bucket.url}/#{self.field_filename(variation_name)}"
    end
    # Attachee_prefix is moved on field_value for S3
    # as well as url_prefix
    def location_root
      File.join(
        settings.root, 
        settings.url_prefix
      )
    end

    def local_url_prefix
      (
        self.field_options[:url_prefix] || 
        self.document.class.settings.s3_url_prefix || 
        settings.url_prefix
      ).gsub(/^\/|\/$/,'')
    end

    def next_available_filename filename
      ext = File.extname(filename)
      base = File.join(
        local_url_prefix, 
        attachee_prefix, 
        File.basename(filename,ext)
      ).gsub(/^\//,'')
      i = 0
      loop do
        suffix = i==0 ? '' : "-#{i}"
        potential_filename = [base,suffix,ext].join
        if settings.bucket.object(potential_filename).exists?
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
      settings.bucket.put_object({
        acl: self.field_options[:acl] || 'public-read',
        key: fn,
        content_type: type,
        body: file,
        metadata: {
          parent_collection: (self.document.class.respond_to?(:collection) ? self.document.class.collection.name : self.attachee_prefix),
        }
      })
      file.close unless hash[:variation].nil?
      fn
    end

    def deletable? variation_name=:original
      !WebUtils.blank? self.field_filename(variation_name)
      # Fine since deleting a non-existent file does not raise an error in S3
    end

    def perform_delete variation_name=:original
      s3file = settings.bucket.object(self.field_filename(variation_name))
      s3file.delete unless s3file.nil?
    end

    class << self

      def ensure_bucket
        raise MissingBucketError, "Attachment class #{self.name} does not have an S3 bucket." if settings.bucket.nil?
      end

      def middleware
        nil
      end

      # def middleware_options
      #   [
      #     {
      #       prefix: settings.url_prefix.dup.gsub(/^\/|\/$/,''), 
      #       db: settings.db,
      #       # lookup: :path
      #     }
      #   ]
      # end

    end

  end

end

