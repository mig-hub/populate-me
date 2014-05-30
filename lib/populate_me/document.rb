require 'populate_me/utils'

module PopulateMe
  module Document

    # PopulateMe::Document is the base for any document
    # the Backend is supposed to deal with.
    #
    # Any module for a specific ORM or ODM should include
    # this module first.
    # It contains what is not specific to a particular kind
    # of database and it provides defaults.
    #
    # It can be used on its own but it keeps everything
    # in memory. Which means it is only for tests and conceptual
    # understanding.

    def self.included(base)
      base.extend ClassMethods
      base.documents = []
      base.next_id = 0
    end

    module ClassMethods
      attr_accessor :documents, :next_id
      def api_get_all
        @documents
      end
      def api_post(doc={})
        inst = self.new(doc)
        return nil if inst.nil?
        if inst['id'].nil?
          inst['id'] = @next_id
          @next_id += 1
        end
        @documents << inst.to_h
        inst
      end
    end

    attr_accessor :to_h, :errors

    def initialize(doc={})
      @to_h = doc
      @errors = {}
    end

    # Hash interface 
    def [](slot)
      @to_h[slot]
    end
    def []=(slot,value)
      @to_h[slot] = value
    end

    # Validation
    def error_on(k,v)
      @errors[k] = (@errors[k]||[]) << v
      self
    end
    def valid?
      @errors = {}
      validate
      @errors.empty?
    end
    def validate; end

    # def save
    #   return nil unless valid?
    #   before_save
    #   if new?
    #     before_create
    #     id = model.collection.insert(@doc)
    #     @doc['_id'] = id
    #     after_create
    #   else
    #     before_update
    #     id = model.collection.update({'_id'=>@doc['_id']}, @doc)
    #     after_update
    #   end
    #   after_save
    #   id.nil? ? nil : self
    # end


  end
end

