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
      return nil if self.field_value.nil?
      return self.field_value if variation_name==:original
      v = self.variations.find{|var|var.name==variation_name}
      Utils.filename_variation(self.field_value, v.name, v.ext)
    end

    def attachee_prefix
      Utils.dasherize_class_name self.document.class.name
    end
    
    def url variation_name=:original
      self.field_filename variation_name
    end

    def location_root
      settings.root
    end

    def location variation_name=:original
      File.join(self.location_root,self.field_filename(variation_name))
    end

    def ensure_local_path
      self.location
    end
    
    def create form_hash
      self.delete

      # Rack 1.6 deletes multipart files after request
      # So we have to create a branded copy
      unbranded_path = "#{form_hash[:tempfile].path}-#{form_hash[:filename]}"
      path = Utils.branded_filename(unbranded_path)
      FileUtils.copy_entry(form_hash[:tempfile].path, path) 

      future_field_value = perform_create form_hash.merge(branded_path: path)
      create_variations path
      future_field_value
    end

    def create_variations path=nil
      return if self.variations.nil? or self.variations.empty?
      if path.nil? or !File.exist?(path)
        path = ensure_local_path
      end
      variations.each do |v|
        self.delete v.name
        v.job.call(path, Utils.filename_variation(path,v.name,v.ext))
      end
    end

    def perform_create form_hash
      form_hash[:branded_path]
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
    set :root, '/'
    set :url_prefix, Dir.tmpdir

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

