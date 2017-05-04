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

      def set_id_field
        field :_id, {type: :id}
      end

      def sort_by f, direction=1
        direction = 1 if direction==:asc
        direction = -1 if direction==:desc
        if f.is_a?(Hash)
          @current_sort = f
        elsif f.is_a?(Array)
          @current_sort = f.inject({}) do |h,pair| 
            h.store(pair[0], pair[1])
            h
          end
        else
          raise(ArgumentError) unless [1,-1].include? direction
          raise(ArgumentError) unless self.new.respond_to? f
          @current_sort = {f => direction}
        end
        self
      end

      def id_string_key
        (self.fields.keys[0]||'_id').to_s
      end

      def set_indexes f, ids=[]
        requests = ids.each_with_index.inject([]) do |list, (id, i)|
          list << {update_one: 
            {
              filter: {self.id_string_key=>id}, 
              update: {'$set'=>{f=>i}}
            }
          }
        end
        collection.bulk_write requests
      end

      def admin_get theid
        theid = BSON::ObjectId.from_string(theid) if BSON::ObjectId.legal?(theid)
        self.cast{ collection.find({id_string_key => theid}).first }
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
      result = self.class.collection.insert_one(self.to_h)
      if result.ok? and self.id.nil?
        self.id = result.inserted_id
      end
      self.id
    end

    def perform_update
      self.class.collection.update_one({'_id'=> self.id}, self.to_h)
      self.id
    end

    def perform_delete
      self.class.collection.delete_one({'_id'=> self.id})
    end
    
  end
end

