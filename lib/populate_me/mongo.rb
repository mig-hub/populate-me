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
          @collection_name ||= Utils.dasherize_class_name self.name
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

      def set_id_field
        self.fields[:_id] = {type: :id, form_field: false}
      end

      def sort_by f, direction=:asc
        if f.is_a?(Array)||f.is_a?(Hash)
          @current_sort = f
        else
          raise(ArgumentError) unless [:asc,:desc].include? direction
          raise(ArgumentError) unless self.new.respond_to? f
          @current_sort = [[f,direction]]
        end
        self
      end

      def admin_get theid
        theid = BSON::ObjectId.from_string(theid) if BSON::ObjectId.legal?(theid)
        hash = self.collection.find_one({'_id'=> theid})
        hash.nil? ? nil : from_hash(hash) 
      end
      alias_method :[], :admin_get

      def admin_find o={}
        query = o.delete(:query) || {}
        o[:sort] ||= @current_sort
        self.collection.find(query, o).map{|d| self.from_hash(d) }
      end

    end

    attr_accessor :_id

    def id; @_id; end
    def id= value; @_id = value; end

    def perform_create
      self.id = self.class.collection.insert(self.to_h) 
    end

    def perform_update
      self.class.collection.update({'_id'=> self.id}, self.to_h)
      self.id
    end

    def perform_delete
      self.class.collection.remove({'_id'=> self.id})
    end
    
  end
end


#  TODO 
# take care of before and after callbacks

