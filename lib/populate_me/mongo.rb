require 'populate_me/document'
require 'mongo'

module PopulateMe

  class MissingMongoDBError < StandardError; end

  class Mongo < Document

    self.settings.instance_eval do
      def collection_name
        puts 'yo'
        if self[:collection_name].respond_to? :call
          self[:collection_name].call
        else
          self[:collection_name]
        end
      end
    end

    class << self

      def inherited sub 
        super
        # self.inherited is not useful anymore because we use ::collection_name 
        # so that the class name exist when this is run.
        # Which is not the case with dynamically created classes.
        #
        # But we'll keep it for legacy code in the meantime.
        # Decide if we want to keep it.
        #
        # If statment is here for dynamically created classes,
        # because Class.new.name==nil and then it breaks (see tests).
        unless sub.name.nil?
          sub.set :collection_name, WebUtils.dasherize_class_name(sub.name)
        end
      end

      def collection_name
        self.settings.collection_name || WebUtils.dasherize_class_name(self.name) 
      end

      def collection
        raise MissingMongoDBError, "Document class #{self.name} does not have a Mongo database." if settings.db.nil?
        settings.db[self.collection_name]
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
        if self.fields[f.to_sym][:direction]==:desc
          ids = ids.dup.reverse
        end
        requests = ids.each_with_index.inject([]) do |list, (theid, i)|
          theid = string_or_object_id theid
          list << {update_one: 
            {
              filter: {self.id_string_key=>theid}, 
              update: {'$set'=>{f=>i}}
            }
          }
        end
        collection.bulk_write requests
      end

      def admin_get theid
        return self.admin_get_multiple(theid) if theid.is_a?(Array)
        theid = string_or_object_id theid
        self.cast{ collection.find({id_string_key => theid}).first }
      end
      alias_method :[], :admin_get

      def admin_get_multiple theids, o={sort: nil}
        clean_ids = theids.uniq.compact.map{|theid| string_or_object_id(theid) }
        items = self.admin_find(o.merge({
          query: {id_string_key => {'$in' => clean_ids} }
        }))
        clean_ids.map do |id|
          items.find{|item| item.id == id}
        end.compact
      end

      def admin_find o={}
        query = o.delete(:query) || {}
        o[:sort] ||= @current_sort
        if o.key?(:fields)
          o[:projection] = o[:fields].inject({}) do |h, f|
            h[f.to_sym] = 1
            h
          end
          o.delete(:fields)
        end
        self.cast{ collection.find(query, o) }
      end

      def admin_find_first o={}
        self.admin_find(o.merge({limit: 1}))[0]
      end

      def admin_distinct field, o={}
        query = o.delete(:query) || {}
        self.collection.distinct field, query, o
      end

      def string_or_object_id theid
        if BSON::ObjectId.legal?(theid)
          BSON::ObjectId.from_string(theid)
        else
          theid
        end
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

