require "populate_me/utils"
require "fileutils"

module PopulateMe

  class Attachment

    attr_accessor :document, :field

    def initialize doc, field
      @document = doc
      @field = field
    end

    def field_value
      self.document.__send__(field)
    end

    def attachee_prefix
      Utils.dasherize_class_name self.document.class.name
    end
    
    def url version=:original
      self.field_value
    end

    def location_root
      self.class.settings[:root]
    end

    def location version=:original
      File.join(self.location_root,self.field_value)
    end
    
    def create hash
      self.delete
      perform_create hash
    end

    def perform_create hash
      hash[:tempfile].path
    end

    def deletable? version=nil
      !Utils.blank?(self.field_value) and File.exist?(self.location)
    end

    def delete version=nil
      # delete all if version is nil
      if self.deletable?
        FileUtils.rm self.location
      end
    end

    class << self

      def settings
        @settings ||= {
          root: '/',
          url_prefix: Dir.tmpdir
        }
      end

      def root path
        self.settings[:root] = File.expand_path(path)
      end

      def url_prefix path
        self.settings[:url_prefix] = path
      end

      def inherited subclass
        subclass::Middleware.parent = subclass
      end

      def middleware
        Rack::Static
      end

      def middleware_options
        [
          {
            urls: [self.settings[:url_prefix]], 
            root: self.settings[:root]
          }
        ]
      end

    end

    class Middleware

      # Used for proxing a rack middleware adapted to the attachment system.
      # The options are then taken from the attachment class.

      class << self
        attr_accessor :parent
      end
      self.parent = PopulateMe::Attachment
      def parent
        self.class.parent
      end

      def initialize app
        @proxied = parent.middleware.new(app,*parent.middleware_options)
      end

      def call env
        @proxied.call env
      end

    end

  end

end

