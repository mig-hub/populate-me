require 'populate_me/document'

module PopulateMe

  module Mongo

    include Document 

    def self.included base 
      Document.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      include Document::ClassMethods

      # Mongo specific method
      def collection_name name=nil
        if name==nil
          @collection_name ||= self.name
        else
          @collection_name = name
        end
      end

      def db new_db=nil
        if new_db==nil
          @db ||= DB 
        else
          @db = new_db
        end
      end

      # Mongo specific method
      def collection
        db[collection_name]
      end

      def [] theid
        theid = BSON::ObjectId.from_string(theid) if BSON::ObjectId.legal?(theid)
        hash = self.collection.find_one({'_id'=> theid})
        hash.nil? ? nil : from_hash(hash) 
      end

      def all
        self.collection.find.map{|d| self.from_hash(d) }
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
      # index = self.class.collection.find_one({'_id'=> self.id})
      raise MissingDocumentError, "No document can be found with this ID: #{self.id}" if self.id.nil?
      self.class.collection.remove({'_id'=> self.id}, {justOne: true})
    end
    
  end
end


#  TODO 
# take care of DB 
# take care of before and after callbacks

