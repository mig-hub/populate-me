module PopulateMe

  HAS_MAGICK = Kernel.system("which magick") # ImageMagick 7
  HAS_CONVERT = Kernel.system("which convert") # ImageMagick 6

  class Variation < Struct.new :name, :ext, :job

    # Simple class to deal with variations of an attachment
    # Mainly variation of images using ImageMagick
    # but it could be anything else like creating the pdf version
    # of a text file

    def initialize name, ext, job_as_proc=nil, &job_as_block
      super name, ext, job_as_proc||job_as_block
    end

    class << self

      def new_image_magick_job name, ext, convert_string, options={}
        o = {
          strip: true, progressive: true,
        }.merge(options)
        defaults = ""
        defaults << "-strip " if o[:strip]
        defaults << "-interlace Plane " if o[:progressive] and [:jpg,:jpeg].include?(ext.to_sym)
        job = lambda{ |src,dst|
          if PopulateMe::HAS_MAGICK
            Kernel.system "magick \"#{src}\" #{defaults}#{convert_string} \"#{dst}\""
          elsif PopulateMe::HAS_CONVERT
            Kernel.system "convert \"#{src}\" #{defaults}#{convert_string} \"#{dst}\""
          else
            puts "ImageMagick not found, niether `magick` nor `convert` commands are available."
          end
        }
        self.new name, ext, job
      end

      def default
        self.new_image_magick_job(:populate_me_thumb, :jpg, "-flatten -resize '400x230' -gravity center -extent 400x230")
      end

    end

  end

end

