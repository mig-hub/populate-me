require "populate_me/attachment"

module PopulateMe

  class FileSystemAttachment < Attachment

    class << self

      def settings
        @settings ||= {
          root: File.expand_path('public'),
          url_prefix: '/attachments'
        }
      end

    end

    def url version=:original
      return nil if Utils.blank?(self.field_value)
      "#{self.class.settings[:url_prefix].sub(/\/$/,'')}/#{self.attachee_prefix}/#{self.field_value}"
    end

    def location_root
      File.join(
        self.class.settings[:root], 
        self.class.settings[:url_prefix],
        self.attachee_prefix
      )
    end
    
    def next_available_filename filename
      FileUtils.mkdir_p self.location_root
      ext = File.extname(filename)
      base = File.basename(filename,ext)
      i = 0
      loop do
        suffix = i==0 ? '' : "-#{1}"
        potential_filename = [base,suffix,ext].join
        potential_location = File.join(self.location_root,potential_filename)
        if File.exist?(potential_location)
          i += 1
        else
          filename = potential_filename
          break
        end
      end
      filename
    end

    def perform_create hash
      filename = next_available_filename hash[:filename]
      destination = File.join(self.location_root,filename)
      FileUtils.cp hash[:tempfile].path, destination
      filename
    end

  end

end

