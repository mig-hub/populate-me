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
      base.before :delete, :ensure_delete_related
      base.after :delete, :ensure_new
    end

    module ClassMethods
      attr_writer :fields, :documents
      attr_accessor :callbacks, :label_field

      def to_s
        super.gsub(/[A-Z]/, ' \&')[1..-1].gsub('::','')
      end

      def to_s_short
        self.name[/[^:]+$/].gsub(/[A-Z]/, ' \&')[1..-1]
      end

      def to_s_plural; "#{self.to_s}s"; end
      def to_s_short_plural; "#{self.to_s_short}s"; end

      def label sym
        @label_field = sym.to_sym
      end

      def fields; @fields ||= {}; end
      def field name, o={}
        set_id_field if self.fields.empty?&&o[:type]!=:id
        complete_field_options name, o
        if o[:type]==:list
          define_method(name) do
            var = "@#{name}"
            instance_variable_set(var, instance_variable_get(var)||[])
          end
        else
          attr_accessor name
        end
        self.fields[name] = o
      end
      def complete_field_options name, o={}
        o[:field_name] = name
        Utils.ensure_key o, :type, :string
        Utils.ensure_key o, :form_field, ![:id,:position].include?(o[:type])
        o[:wrap] = false unless o[:form_field]
        Utils.ensure_key o, :wrap, ![:hidden,:list].include?(o[:type])
        Utils.ensure_key o, :label, Utils.label_for_field(name)
        if o[:type]==:list
          o[:class_name] = Utils.guess_related_class_name(self.name,o[:class_name]||name)
          o[:dasherized_class_name] = Utils.dasherize_class_name o[:class_name]
        else
          Utils.ensure_key o, :input_attributes, {}
          o[:input_attributes][:type] = :hidden if o[:type]==:hidden
          unless o[:type]==:text
            Utils.ensure_key o[:input_attributes], :type, :text
          end
        end
      end
      def set_id_field
        field :id, {type: :id}
      end
      def position_field o={}
        name = o[:name]||'position'
        o[:type] = :position
        field name, o
        sort_by name
      end
      def label_field
        @label_field || self.fields.keys[1]
      end

      def relationships; @relationships ||= {}; end
      def relationship name, o={}
        o[:class_name] = Utils.guess_related_class_name(self.name,o[:class_name]||name)
        Utils.ensure_key o, :label, name.to_s.capitalize
        Utils.ensure_key o, :foreign_key, "#{Utils.dasherize_class_name(self.name).gsub('-','_')}_id"
        o[:foreign_key] = o[:foreign_key].to_sym
        Utils.ensure_key o, :dependent, true
        self.relationships[name] = o
      end

      def documents; @documents ||= []; end

      def from_hash hash, o={}
        self.new(_is_new: false).set_from_hash hash, o
      end

      def sort_by f, direction=:asc
        raise(ArgumentError) unless [:asc,:desc].include? direction
        raise(ArgumentError) unless self.new.respond_to? f
        @sort_proc = Proc.new do |a,b|
          a,b = b,a if direction==:desc 
          a.__send__(f)<=>b.__send__(f) 
        end
        self
      end

      def id_string_key
        (self.fields.keys[0]||'id').to_s
      end

      def set_indexes f, ids=[]
        ids.each_with_index do |id,i|
          self.documents.each do |d|
            d[f.to_s] = i if d[self.id_string_key]==id
          end
        end
        self
      end

      def admin_get id
        hash = self.documents.find{|doc| doc[self.id_string_key]==id }
        return nil if hash.nil?
        from_hash hash
      end

      def admin_find o={}
        o[:query] ||= {}
        docs = self.documents.map do |d| 
          self.from_hash(d) 
        end.find_all do |d|
          o[:query].inject(true) do |out,(k,v)|
            out && (d.__send__(k)==v)
          end
        end
        docs.sort!(&@sort_proc) if @sort_proc.is_a?(Proc)
        docs
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

    end

    attr_accessor :id, :_errors, :_is_new

    def errors; self._errors; end
    def new?; self._is_new; end

    def persistent_instance_variables
      instance_variables.select do |k|
        if self.class.fields.empty?
          k !~ /^@_/
        else
          self.class.fields.key? k[1..-1].to_sym
        end
      end
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

    def nested_docs
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

    def set_defaults o={}
      self.class.fields.each do |k,v|
        if v.key?(:default)&&(__send__(k).nil?||o[:force])
          set k.to_sym => Utils.get_value(v[:default],self)
        end
      end
      self
    end

    def set_from_hash hash, o={}
      raise(TypeError, "#{hash} is not a Hash") unless hash.is_a? Hash
      hash = hash.dup # Leave original untouched
      hash.delete('_class')
      hash.each do |k,v|
        if v.is_a? Array
          __send__(k.to_sym).clear
          v.each do |d|
            obj =  Utils.resolve_class_name(d['_class']).new.set_from_hash(d)
            __send__(k.to_sym) << obj
          end
        else
          v = typecast(k.to_sym,v) if o[:typecast]
          set k.to_sym => v
        end
      end
      self
    end

    # Typecasting
    def typecast k, v
      return Utils.automatic_typecast(v) unless self.class.fields.key?(k)
      meth = "typecast_#{self.class.fields[k][:type]}".to_sym
      return Utils.automatic_typecast(v) unless respond_to?(meth)
      __send__ meth, k, v
    end
    def typecast_integer k, v
      v.to_i
    end
    def typecast_price k, v
      return nil if Utils.blank?(v)
      Utils.parse_price(v)
    end
    def typecast_date k, v
      if v[/\d\d(\/|-)\d\d(\/|-)\d\d\d\d/]
        Date.parse v
      else
        nil
      end
    end
    def typecast_datetime k, v
      if v[/\d\d(\/|-)\d\d(\/|-)\d\d\d\d \d\d?:\d\d?:\d\d?/]
        d,m,y,h,min,s = v.split(/[-:\s\/]/)
        Time.utc(y,m,d,h,min,s)
      else
        nil
      end
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
      nested_docs.each do |d|
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
    def ensure_delete_related # before_delete
      self.class.relationships.each do |k,v|
        if v[:dependent]
          klass = Utils.resolve_class_name v[:class_name]
          next if klass.nil?
          klass.admin_find(query: {v[:foreign_key]=>self.id}).each do |d|
            d.delete
          end
        end
      end
    end

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
      nested_docs.reduce self._errors.empty? do |result,d|
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

    def to_admin_url
      "#{Utils.dasherize_class_name(self.class.name)}/#{id}".sub(/\/$/,'')
    end

    # Admin list
    module ClassMethods
      def sort_field_for o={}
        filter = o[:params][:filter]
        return nil if !filter.nil?&&filter.size>1
        expected_scope = filter.nil? ? nil : filter.keys[0].to_sym
        f = self.fields.find do |k,v| 
          v[:type]==:position&&v[:scope]==expected_scope
        end
        f.nil? ? nil : f[0]
      end
      def to_admin_list o={}
        o[:params] ||= {}
        unless o[:params][:filter].nil?
          query = o[:params][:filter].inject({}) do |query, (k,v)|
            query[k.to_sym] = self.new.typecast(k,v)
            query
          end
          new_data = Rack::Utils.build_nested_query(data: o[:params][:filter])
        end
        {
          template: 'template_list',
          page_title: self.to_s_short_plural,
          dasherized_class_name: PopulateMe::Utils.dasherize_class_name(self.name),
          new_data: new_data,
          sort_field: self.sort_field_for(o),
          # 'command_plus'=> !self.populate_config[:no_plus],
          # 'command_search'=> !self.populate_config[:no_search],
          items: self.admin_find(query: query).map do |d| 
            d.to_admin_list_item(o) 
          end
        }
      end
    end
    def to_admin_list_item o={}
      {
        class_name: self.class.name,
        id: self.id,
        admin_url: to_admin_url,
        title: to_s,
        local_menu: self.class.relationships.inject([]) do |out,(k,v)|
          unless v[:hidden]
            out << {
              title: "#{v[:label]}",
              href: "#{o[:request].script_name}/list/#{Utils.dasherize_class_name(v[:class_name])}?filter[#{v[:foreign_key]}]=#{self.id}"
            }
            out
          end
        end
      }
    end

    # Forms
    def to_admin_form o={}
      Utils.ensure_key o, :input_name_prefix, 'data'
      class_item = {
        type: :hidden,
        input_name: "#{o[:input_name_prefix]}[_class]",
        input_value: self.class.name,
      }
      self.class.complete_field_options :_class, class_item
      items = self.class.fields.inject([class_item]) do |out,(k,item)|
        item = item.dup
        if item[:form_field]
          outcast k, item, o
          out << item
        end
        out
      end
      {
        template: "template#{'_nested' if o[:nested]}_form",
        page_title: self.new? ? "New #{self.class.to_s_short}" : self.to_s,
        admin_url: self.to_admin_url,
        is_new: self.new?,
        fields: items
      }
    end

    def outcast field, item, o={}
      item[:input_name] = "#{o[:input_name_prefix]}[#{item[:field_name]}]"
      unless item[:type]==:list
        Utils.ensure_key item, :input_value, self.__send__(field)
      end
      meth = "outcast_#{item[:type]}".to_sym
      __send__(meth, field, item, o) if respond_to?(meth)
    end

    def outcast_list field, item, o={}
      item[:items] = self.__send__(field).map do |nested|
       nested.to_admin_form(o.merge(input_name_prefix: item[:input_name]+'[]'))
      end
    end

    def outcast_select field, item, o={}
      unless item[:select_options].nil?
        opts = Utils.get_value(item[:select_options],self).dup
        opts.map! do |opt|
          if opt.is_a?(String)||opt.is_a?(Symbol)
            opt = [opt.to_s.capitalize,opt]
          end
          if opt.is_a?(Array)
            opt = {description: opt[0].to_s, value: opt[1].to_s}
          end
          opt[:selected] = true if item[:input_value]==opt[:value]
          opt
        end
        item[:select_options] = opts
      end
    end

  end
end

