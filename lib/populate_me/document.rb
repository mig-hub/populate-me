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
      attr_writer :fields, :documents
      attr_accessor :callbacks, :label_field

      def to_s
        super.gsub(/[A-Z]/, ' \&')[1..-1].gsub('::','')
      end

      def to_s_plural; "#{self.to_s}s"; end

      def label sym
        @label_field = sym.to_sym
      end

      def fields; @fields ||= {}; end
      def field name, attributes={}
        if attributes[:type]==:list
          define_method(name) do
            var = "@#{name}"
            instance_variable_set(var, instance_variable_get(var)||[])
          end
        else
          attr_accessor name
        end
        self.fields[name] = attributes
      end
      def label_field
        @label_field || self.fields.keys[0]
      end

      def documents; @documents ||= []; end

      def from_hash hash, o={}
        self.new(_is_new: false).set_from_hash hash, o
      end

      # def typecast(hash)
      #   Utils.each_stub hash do |object,key_index,value|
      #     object[key_index] = Utils.automatic_typecast value
      #   end
      # end

      def from_post hash
        # Utils.each_stub hash do |object,key_index,value|
        #   object[key_index] = Utils.automatic_typecast value
        # end
        doc = from_hash hash
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
      def all
        self.documents.map{|d| self.from_hash(d) }
      end
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
      attributes.dup.each do |k,v| 
        __send__ "#{k}=", v
      end
      self
    end

    def set_from_hash hash, o={}
      raise(TypeError, "#{hash} is not a Hash") unless hash.is_a? Hash
      hash = hash.dup # Leave original untouched
      hash.delete('_class')
      hash.each do |k,v|
        if v.is_a? Array
          v.each do |d|
            obj =  Utils.resolve_class_name(d['_class']).new.set_from_hash(d)
            __send__(k.to_sym) << obj
          end
        else
          v = Utils.automatic_typecast(v) if o[:typecast]
          set k.to_sym => v
        end
      end
      self
    end

    def persistent_instance_variables
      instance_variables.select{|k| k !~ /^@_/ }
    end

    def to_h
      persistent_instance_variables.inject({'_class'=>self.class.name}) do |h,var|
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
      "#<#{self.class.name}:#{to_h.inspect}>"
    end

    def to_s
      return inspect if self.class.label_field.nil?
      me = __send__(self.class.label_field)
      Utils.blank?(me) ? inspect : me
    end

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
      self
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

    # Related to the Admin interface #############
    require "populate_me/builder"

    def to_admin_url
      "#{Utils.dasherize_class_name(self.class.name)}/#{id}".sub(/\/$/,'')
    end

    # Admin list
    def to_admin_list_item o={}
      {
        class_name: self.class.name,
        id: self.id,
        admin_url: to_admin_url,
        title: to_s
      }
    end

    # Forms
    def default_form o={}
      Builder.create_here do |b|
        self.class.fields.keys.each do |k|
          b.input_for(self,k)
        end
      end
    end
    def to_admin_form o={}
      # merge input_attributes with defaults
      items = []
      if self.class.respond_to? :fields
        self.class.fields.each do |k,v|
          unless v[:form_field]==false
            settings = v.dup
            settings[:field_name] = k
            settings[:wrap] ||= true
            settings[:wrap] = false if settings[:type]==:hidden
            settings[:label] ||= PopulateMe::Utils.label_for_field k
            settings[:input_name] = "#{o[:input_name_prefix]||'data'}[#{k}]"
            if settings[:type]==:list
              settings[:items] = self.__send__(k).map {|embeded|
               embeded.to_admin_form(o.merge(input_name_prefix: settings[:input_name]))
              }
            else
              settings[:input_value] = self.__send__ k
              settings[:input_attributes] = {
                type: 'text', name: settings[:input_name],
                value: settings[:input_value], required: settings[:required]
              }.merge(settings[:input_attributes]||{})
            end
            items << settings
          end
        end
      end
      items
    end

  end
end

