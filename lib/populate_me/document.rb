require 'populate_me/utils'

module PopulateMe
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

    attr_accessor :_errors, :_is_new

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
      validate
      self._errors.empty?
    end
    def validate; end

    def save
      before_save
      if new?
        before_create
        id = perform_create
        self._is_new = false unless id.nil?
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
      self.respond_to?(:id) ? self.id : nil
    end
    def perform_update
    end
    def before_save; end
    def after_save; end
    def before_create; end
    def after_create; end
    def before_update; end
    def after_update; end

  end
end

