require 'populate_me/utils'
require 'populate_me/variation'
require 'fileutils'
require 'ostruct'

module PopulateMe

  class Attachment

    class << self

      attr_accessor :settings

      # inheritable settings
      def set name, value
        self.settings[name] = value
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

    def variations
      self.document.class.fields[self.field][:variations]
    end

    def field_filename variation_name=:original
      return nil if Utils.blank?(self.field_value)
      return self.field_value if variation_name==:original
      v = self.variations.find{|var|var.name==variation_name}
      Utils.filename_variation(self.field_value, v.name, v.ext)
    end

    def attachee_prefix
      Utils.dasherize_class_name self.document.class.name
    end
    
    def url variation_name=:original
      return nil if Utils.blank?(self.field_filename(variation_name))
      "#{settings.url_prefix.sub(/\/$/,'')}/#{self.attachee_prefix}/#{self.field_filename(variation_name)}"
    end

    def location_root
      File.join(
        settings.root, 
        settings.url_prefix,
        self.attachee_prefix
      )
    end

    def location variation_name=:original
      self.location_for_filename self.field_filename(variation_name)
    end
    def location_for_filename filename
      File.join self.location_root, filename
    end

    def ensure_local_path
      self.location
    end
    
    def create form_hash
      self.delete
      future_field_value = perform_create form_hash
      create_variations form_hash.merge({future_field_value: future_field_value})
      future_field_value
    end

    def create_variations hash
      return if self.variations.nil?
      tmppath = hash[:tempfile].path
      path = self.location_for_filename hash[:future_field_value]
      variations.each do |v|
        self.delete v.name
        v_path = Utils.filename_variation path, v.name, v.ext
        v.job.call tmppath, v_path
        self.perform_create hash.merge({variation: v, variation_path: v_path})
      end
    end

    def perform_create hash
      return File.basename(hash[:variation_path]) unless Utils.blank?(hash[:variation_path])
      # Rack 1.6 deletes multipart files after request
      # So we have to create a copy
      FileUtils.mkdir_p self.location_root
      tmppath = hash[:tempfile].path
      unique_prefix = File.basename(tmppath, File.extname(tmppath))
      unique_filename = "#{unique_prefix}-#{hash[:filename]}"
      path = self.location_for_filename unique_filename
      FileUtils.copy_entry(tmppath, path) 
      unique_filename
    end

    def deletable? variation_name=:original
      !Utils.blank?(self.field_filename(variation_name)) and File.exist?(self.location(variation_name))
    end

    def delete variation_name=:original
      if self.deletable?(variation_name)
        perform_delete variation_name
      end
    end

    def delete_all
      to_delete =  [:original] + variations.map(&:name)
      to_delete.each do |v_name|
        self.delete v_name
      end
    end

    def perform_delete variation_name=:original
      FileUtils.rm self.location(variation_name)
    end

    self.settings = OpenStruct.new
    set :root, File.join(Dir.tmpdir, 'populate-me')
    set :url_prefix, '/attachment'
    FileUtils.mkdir_p self.settings.root

    class Middleware

      # Used for proxing a rack middleware adapted to the attachment system.
      # The options are then taken from the attachment class.
      # It can be used in rackup file as:
      #
      # use AtachmentClass::Middleware

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

