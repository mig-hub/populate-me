require 'populate_me/document'


module PopulateMe

  module Mongo

    include Document 

    def self.included base 
      base.extend ClassMethods
    end

    module ClassMethods
      # include Document::ClassMethods
    end

    

  end
end
