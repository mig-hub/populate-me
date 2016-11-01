require 'populate_me/document'
require 'mongo'

module PopulateMe

  class MissingMongoDBError < StandardError; end

  class Mongo < Document

    class << self

      def inherited sub 
        super
        sub.set :collection_name, WebUtils.dasherize_class_name(sub.name)
      end

      def collection
        raise MissingMongoDBError, "Document class #{self.name} does not have a Mongo database." if settings.db.nil?
        settings.db[settings.collection_name]
      end

      def bulk o={}
        o[:ordered] ||= true
        b = o[:ordered] ? collection.initialize_ordered_bulk_op : collection.initialize_unordered_bulk_op
        if block_given?
          yield b
          b.execute
        end
      end

      def set_id_field
        field :_id, {type: :id}
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

      def id_string_key
        (self.fields.keys[0]||'_id').to_s
      end

      def set_indexes f, ids=[]
        bulk do |b|
          ids.each_with_index do |id,i|
            b.find(self.id_string_key=>id).update_one({'$set'=>{f=>i}})
          end
        end
      end

      def admin_get theid
        theid = BSON::ObjectId.from_string(theid) if BSON::ObjectId.legal?(theid)
        self.cast{ collection.find_one({id_string_key => theid}) }
      end
      alias_method :[], :admin_get

      def admin_find o={}
        query = o.delete(:query) || {}
        o[:sort] ||= @current_sort
        self.cast{ collection.find(query, o) }
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

