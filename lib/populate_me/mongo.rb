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

      # def db new_db=nil
      #   if new_db==nil
      #     # raise(StandardError, "DB not set!") if !defined?(:DB)
      #     @db ||= DB 
      #   else
      #     @db = new_db
      #   end
      def db 
        DB
      end

      def collection
        db[collection_name]
      end

    end

    def set_from_hash hash, o={}
      super
    end

    def to_h
      super
    end
    

    def perform_create
      id = self.class.collection.insert(self.to_h)
      self.to_h['_id'] = id
    end

    def perform_update
      id = self.class.collection.update({id: self.to_h['_id']}, self.to_h)
      self.to_h['_id'] = id
    end

    def perform_delete
      
    end
    
  end
end
