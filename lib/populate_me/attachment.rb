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
    
    def url version=:original
      self.field_value
    end
    
    def create hash
      if !Utils.blank?(self.field_value) and File.exist?(self.field_value)
        self.delete
      end
      hash[:tempfile].path
    end

    def delete version=nil
      # delete all if version is nil
      FileUtils.rm self.field_value
    end

    def self.inherited subclass
      subclass::Middleware.parent = subclass
    end

    def self.middleware
      Rack::Static
    end

    def self.middleware_options
      [{urls: [Dir.tmpdir], root: '/'}]
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

