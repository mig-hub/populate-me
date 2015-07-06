require "populate_me/utils"
require "fileutils"
require "ostruct"

module PopulateMe

  class Attachment

    Variation = Struct.new :name, :ext, :job

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

      # Variation
      
      def variation name, ext, job_as_proc=nil, &job_as_block
        Variation.new name, ext, job_as_proc||job_as_block
      end
      def image_magick_variation name, ext, convert_string, options={}
        o = {
          strip: true, progressive: true,
        }.merge(options)
        defaults = ""
        defaults << "-strip " if o[:strip]
        defaults << "-interlace Plane " if o[:progressive] and [:jpg,:jpeg].include?(ext.to_sym)
        job = lambda{ |src,dst|
          Kernel.system "convert \"#{src}\" #{defaults}#{convert_string} \"#{dst}\""
        }
        Variation.new name, ext, job
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

    def field_filename version=nil
      self.field_value
    end

    def attachee_prefix
      Utils.dasherize_class_name self.document.class.name
    end
    
    def url version=:original
      self.field_filename
    end

    def location_root
      settings.root
    end

    def location version=:original
      File.join(self.location_root,self.field_filename)
    end

    def ensure_local_path
      self.location
    end
    
    def create hash
      self.delete
      out = perform_create hash
      create_variations hash[:tempfile].path
      out
    end

    def create_variations path=nil
      variations = self.document.class.fields[self.field][:variations]
      return if variations.nil? or variations.empty?
      if path.nil? or !File.exist?(path)
        path = ensure_local_path
      end
      variations.each do |v|
        v.job.call(path, Utils.filename_variation(path,v.name,v.ext))
      end
    end

    def perform_create hash
      # Rack 1.6 deletes multipart files after request
      src = hash[:tempfile].path
      dst = Utils.branded_filename(src)
      FileUtils.copy_entry(src,dst) 
      dst
    end

    def deletable? version=nil
      !Utils.blank?(self.field_filename) and File.exist?(self.location)
    end

    def delete version=nil
      # delete all if version is nil
      if self.deletable?
        perform_delete version
      end
    end

    def perform_delete version=nil
      FileUtils.rm self.location
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

