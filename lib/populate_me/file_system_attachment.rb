require 'populate_me/attachment'

module PopulateMe

  class FileSystemAttachment < Attachment

    set :root, File.expand_path('public')
    
    def next_available_filename filename
      FileUtils.mkdir_p self.location_root
      ext = File.extname(filename)
      base = File.basename(filename,ext)
      i = 0
      loop do
        suffix = i==0 ? '' : "-#{i}"
        potential_filename = [base,suffix,ext].join
        potential_location = self.location_for_filename(potential_filename)
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
      return File.basename(hash[:variation_path]) unless WebUtils.blank?(hash[:variation_path])
      source = hash[:tempfile].path
      filename = self.next_available_filename hash[:filename]
      destination = self.location_for_filename filename
      FileUtils.cp source, destination
      filename
    end

  end

end

