require "populate_me/attachment"

module PopulateMe

  class FileSystemAttachment < Attachment

    def self.settings
      @settings ||= {
        root: 'public',
        url_prefix: '/attachments'
      }
    end

  end

end

