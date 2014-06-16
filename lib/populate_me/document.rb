require 'populate_me/utils'


module PopulateMe

  class MissingDocumentError < StandardError; end

  module Document

    def self.included base 
      base.extend ClassMethods
    end

    module ClassMethods
      attr_accessor :_documents

      def documents; self._documents ||= []; end

      def from_hash hash
        doc = self.new
        hash.each do |k,v|
          doc.set k.to_sym => v
        end
        doc._is_new = false
        doc
      end

      # def api_get_all
      #   @documents
      # end
      # def api_post doc={} 
      #   inst = self.new(doc)
      #   return nil if inst.nil?
      #   if inst['id'].nil?
      #     inst['id'] = @next_id
      #     @next_id += 1
      #   end
      #   @documents << inst.to_h
      #   inst
      # end
    end

    attr_accessor :id, :_errors, :_is_new

    def errors; self._errors; end
    def new?; self._is_new; end

    def initialize attributes=nil 
      set attributes if attributes
      self._is_new = true
      self._errors = {}
    end

    def set attributes
      attributes.each{|k,v| __send__ "#{k}=", v }
      self
    end

    def persistent_instance_variables
      instance_variables.select{|k| k !~ /^@_/ }
    end

    def to_h
      persistent_instance_variables.inject({}) do |h,var|
        k = var.to_s[1..-1]
        v = instance_variable_get var
        h[k] = v
        h
      end
    end
    alias_method :to_hash, :to_h

    def == other
      other.to_h==to_h
    end

    def inspect
      "#<#{self.class}:#{to_h.inspect}>"
    end
    alias_method :to_s, :inspect

    # Validation
    def error_on k,v 
      self._errors[k] = (self._errors[k]||[]) << v
      self
    end
    def valid?
      self._errors = {}
      before_validation
      validate
      after_validation
      self._errors.empty?
    end
    def validate; end
    def before_validation; end
    def after_validation; end

    # Saving
    def save
      before_save
      if new?
        before_create
        id = perform_create
        after_create
      else
        before_update
        id = perform_update
        after_update
      end
      after_save
      id
    end
    def perform_create
      self.class.documents << self.to_h
      self.id
    end
    def perform_update
      index = self.class.documents.index{|d| d['id']==self.id }
      raise MissingDocumentError, "No document can be found with this ID: #{self.id}" if self.id.nil?||index.nil?
      self.class.documents[index] = self.to_h
    end
    def before_save; end
    def after_save; end
    ID_CHARS = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    ID_SIZE = 16
    def before_create
      if self.id.nil?
        self.id = ID_SIZE.times{self.id << ID_CHARS[rand(ID_CHARS.size)]} 
      end
    end
    def after_create; self._is_new = false; end
    def before_update; end
    def after_update; end

    # Deletion
    def delete o={}
    end
    def perform_delete
      index = self.class.documents.index{|d| d['id']==self.id }
      raise MissingDocumentError, "No document can be found with this ID: #{self.id}" if self.id.nil?||index.nil?
      self.class.documents.delete_at(index)
    end

  end
end

