require 'populate_me/utils'


module PopulateMe

  class MissingDocumentError < StandardError; end

  module Document

    def self.included base 
      base.extend ClassMethods
      [:save,:create,:update,:delete].each do |cb|
        base.before cb, :recurse_callback
        base.after cb, :recurse_callback
      end
      base.before :create, :ensure_id
      base.after :create, :ensure_not_new
      base.after :delete, :ensure_new
    end

    module ClassMethods
      attr_writer :documents
      attr_accessor :callbacks

      def documents; @documents ||= []; end

      def from_hash hash
        raise(TypeError, "#{hash} is not a Hash") unless hash.is_a? Hash
        hash = hash.dup # Leave original untouched
        hash.delete('_class')
        doc = self.new
        hash.each do |k,v|
          if v.is_a? Array
            v.each do |d|
              raise d.inspect if d['_class'].nil?
              obj =  Utils.resolve_class_name(d['_class']).from_hash(d)
              doc.__send__(k.to_sym) << obj
            end
          else
            doc.set k.to_sym => v
          end
        end
        doc._is_new = false
        doc
      end

      def from_post hash
        # Utils.each_stub hash do |object,key_index,value|
        #   object[key_index] = Utils.automatic_typecast value
        # end
        doc = from_hash hash
        doc._is_new = true
        doc
      end

      def [] id
        hash = self.documents.find{|doc| doc['id']==id }
        return nil if hash.nil?
        from_hash hash
      end

      # Callbacks
      def register_callback name, item=nil, options={}, &block
        name = name.to_sym
        if block_given?
          options = item || {}
          item = block
        end
        @callbacks ||= {}
        @callbacks[name] ||= []
        if options[:prepend]
          @callbacks[name].unshift item
        else
          @callbacks[name] << item
        end
      end
      def before name, item=nil, options={}, &block
        register_callback "before_#{name}", item, options, &block
      end
      def after name, item=nil, options={}, &block
        register_callback "after_#{name}", item, options, &block
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
      self._is_new = true
      set attributes if attributes
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
      persistent_instance_variables.inject({'_class'=>self.class.to_s}) do |h,var|
        k = var.to_s[1..-1]
        v = instance_variable_get var
        if v.is_a? Array
          h[k] = v.map(&:to_h)
        else
          h[k] = v
        end
        h
      end
    end
    alias_method :to_hash, :to_h

    def embeded_docs
      persistent_instance_variables.map do |var|
        instance_variable_get var
      end.find_all do |val|
        val.is_a? Array
      end.flatten
    end

    def == other
      return false unless other.respond_to?(:to_h)
      other.to_h==to_h
    end

    def inspect
      "#<#{self.class}:#{to_h.inspect}>"
    end
    alias_method :to_s, :inspect

    # Callbacks
    def exec_callback name
      name = name.to_sym
      return self if self.class.callbacks[name].nil?
      self.class.callbacks[name].each do |job|
        if job.respond_to?(:call)
          self.instance_exec name, &job
        else
          meth = self.method(job)
          meth.arity==1 ? meth.call(name) : meth.call
        end
      end
      self
    end
    def recurse_callback name
      embeded_docs.each do |d|
        d.exec_callback name
      end
    end
    def ensure_id # before_create
      if self.id.nil?
        self.id = Utils::generate_random_id
      end
    end
    def ensure_new; self._is_new = true; end # after_delete
    def ensure_not_new; self._is_new = false; end # after_create

    # Validation
    def error_on k,v 
      self._errors[k] = (self._errors[k]||[]) << v
      self
    end
    def valid?
      self._errors = {}
      exec_callback :before_validate
      validate
      exec_callback :after_validate
      return false unless self._errors.empty?
      embeded_docs.reduce true do |result,d|
        result &= d.valid?
      end
    end
    def validate; end

    # Saving
    def save
      return unless valid?
      exec_callback :before_save
      if new?
        exec_callback :before_create
        id = perform_create
        exec_callback :after_create
      else
        exec_callback :before_update
        id = perform_update
        exec_callback :after_update
      end
      exec_callback :after_save
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

    # Deletion
    def delete o={}
      exec_callback :before_delete
      perform_delete
      exec_callback :after_delete
    end
    def perform_delete
      index = self.class.documents.index{|d| d['id']==self.id }
      raise MissingDocumentError, "No document can be found with this ID: #{self.id}" if self.id.nil?||index.nil?
      self.class.documents.delete_at(index)
    end

  end
end

