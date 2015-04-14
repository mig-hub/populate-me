require "populate_me/utils"
require "fileutils"
require "ostruct"

module PopulateMe

  class Attachment

    class << self

      attr_accessor :settings

      # inheritable settings
      def set name, value
        self.settings[name] = value
      end


      def root path
        settings.root = File.expand_path(path)
      end

      def url_prefix path
        settings.url_prefix = path
      end

      def inherited sub
        super
        sub.settings = settings.dup
        sub::Middleware.parent = sub
      end

      def middleware
        Rack::Static
      end

      def middleware_options
        [
          {
            urls: [settings.url_prefix], 
            root: settings.root
          }
        ]
      end

    end

    attr_accessor :document, :field

    def initialize doc, field
      @document = doc
      @field = field
    end

    def settings
      self.class.settings
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
      settings.root
    end

    def location version=:original
      File.join(self.location_root,self.field_value)
    end
    
    def create hash
      self.delete
      perform_create hash
    end

    def perform_create hash
      # Rack 1.6 deletes multipart files after request
      src = hash[:tempfile].path
      dest = "#{File.dirname(src)}/PopulateMe-#{File.basename(src)}"
      FileUtils.copy_entry(src,dest) 
      dest
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

    self.settings = OpenStruct.new
    set :root, '/'
    set :url_prefix, Dir.tmpdir

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

