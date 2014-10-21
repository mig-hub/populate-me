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

    attr_accessor :_id

    def id; @_id; end
    def id= value; @_id = value; end

    def persistent_instance_variables
      if instance_variable_get(:@_id).nil?
        super
      else
        [:@_id]+super
      end
    end

    def perform_create
      self.id = self.class.collection.insert(self.to_h) 
    end

    def perform_update
      self.class.collection.update({'_id'=> self.id}, self.to_h)
      self.id
    end

    def perform_delete
      
    end
    
  end
end
