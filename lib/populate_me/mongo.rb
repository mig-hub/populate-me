require 'populate_me/document'


module PopulateMe

  module Mongo

    include Document 

    def self.included base 
      base.extend ClassMethods
    end

    module ClassMethods
      include Document::ClassMethods


      def collection_name name=nil
        if name==nil
          @collection_name ||= self.name
        else
          @collection_name = name
        end
      end

      def db new_db=nil
        if new_db==nil
          raise "DB not set !" if !defined?(DB)
          @db ||= DB 
        else
          @db = new_db
        end
      end

      def collection
        db[collection_name]
      end

    end

    def perform_create
      self.id
    end

    def perform_update
      self.id
    end

    def perform_delete
      self.id
    end
    
  end
end
