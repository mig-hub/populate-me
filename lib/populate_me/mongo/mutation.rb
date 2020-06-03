# encoding: utf-8
module PopulateMe
  module Mongo
    module Mutation
  
      # Most important MongoDB module
      # It defines the ODM
  
      def self.included(weak)
        weak.extend(MutateClass)
        weak.db = DB if defined?(DB)
        weak.schema = {}
        weak.relationships = {}
      end

      module MutateClass
        attr_accessor :db, :schema, :relationships
        attr_writer :label_column, :slug_column, :sorting_order

        LABEL_COLUMNS = ['title', 'label', 'fullname', 'full_name', 'surname', 'lastname', 'last_name', 'name', 'firstname', 'first_name', 'login', 'caption', 'reference', 'file_name', 'body', '_id']
        def label_column; @label_column ||= LABEL_COLUMNS.find{|c| @schema.keys.include?(c)||c=='_id'}; end
        def slug_column; @slug_column ||= (@schema.find{|k,v| v[:type]==:slug}||[])[0]; end
        def foreign_key_name(plural=false); "id#{'s' if plural}_"+self.name; end
        def human_name; self.name.gsub(/([A-Z])/, ' \1')[1..-1]; end
        def human_plural_name; human_name+'s'; end
        def collection; db[self.name]; end
        def correct_id_class(id)
          if id.is_a?(String)&&BSON::ObjectId.legal?(id)
            return BSON::ObjectId.from_string(id)
          elsif !id.is_a?(BSON::ObjectId)
            return ''
          end
          id
        end
        def ref(id)
          {'_id' => (id.kind_of?(Array) ? {'$in'=> id.map{|i|correct_id_class(i)} } : correct_id_class(id)) }
        end
        def find(selector={},opts={})
          selector.update(opts.delete(:selector)||{})
          opts = {:sort=>self.sorting_order}.update(opts)
          if opts.key?(:fields)
            opts[:projection] = opts[:fields].inject({}) do |h, f|
              h[f.to_sym] = 1
              h
            end
            opts.delete(:fields)
          end
          cur = collection.find(selector,opts)
          cur.instance_variable_set('@mutant_class', self)
          cur.extend(CursorMutation)
        end
        def find_one(spec_or_object_id=nil,opts={})
          spec_or_object_id.nil? ? spec_or_object_id = opts.delete(:selector) : spec_or_object_id.update(opts.delete(:selector)||{})
          opts = {:sort=>self.sorting_order}.update(opts)
          item = collection.find(spec_or_object_id,opts).first
          item.nil? ? nil : self.new(item)
        end
        def count(opts={}); collection.count(opts); end

        def sorting_order
          @sorting_order ||= if @schema.key?('position')&&!@schema['position'][:scope].nil?
            {@schema['position'][:scope] => 1, 'position' => 1}
          elsif @schema.key?('position')
            {'position' => 1, '_id' => 1}
          else
            {'_id' => 1}
          end
        end

        def sort(ids)
          requests = ids.each_with_index.inject([]) do |list, (id, i)|
            list << {update_one: 
              {
                filter: ref(id), 
                update: {'$set'=>{'position'=>i}}
              }
            }
          end
          collection.bulk_write requests
        end

        # CRUD
        def get(id, opts={}); doc = collection.find(ref(id), opts).first; doc.nil? ? nil : self.new(doc); end
        def delete(id); collection.delete_one(ref(id)); end

        def get_multiple(ids, opts={})
          corrected_ids = ids.map{|id| correct_id_class(id) }
          sort_proc = proc{ |a,b| corrected_ids.index(a['_id'])<=>corrected_ids.index(b['_id']) }
          self.find(ref(corrected_ids), opts).to_a.sort(&sort_proc)
        end

    		def is_unique(doc={})
    		  return unless collection.count==0
    		  self.new(doc).save 
    		end

        private
        def slot(name,opts={})
          @schema[name] = {:type=>:string}.update(opts)
          define_method(name) { @doc[name] }
          define_method("#{name}=") { |x| @doc[name] = x }
        end
        def image_slot(name='image',opts={})
          slot name, {:type=>:attachment}.update(opts)
          slot "#{name}_tooltip"
          slot "#{name}_alternative_text"
        end
        def has_many(k,opts={}); @relationships[k] = opts; end
      end
  
      # Instance Methods

      attr_accessor :doc, :old_doc, :errors, :is_new
      def initialize(document=nil); @errors={}; @doc = document || default_doc; end
      def default_doc
        @is_new = true
        out = {}
        model.schema.each { |k,v| out.store(k,v[:default].is_a?(Proc) ? v[:default].call : v[:default]) }
        out
      end
      def model; self.class; end
      def id; @doc['_id']; end
      def [](field); @doc[field]; end
      def []=(field,val); @doc[field] = val; end
      def to_label;  @doc[model.label_column].to_s.tr("\n\r", ' '); end
      ACCENTS_FROM = 
      "ÀÁÂÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđÈÉÊËèéêëĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀŁłÑñŃńŅņŇňŉŊŋÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞ"
      ACCENTS_TO = 
      "AAAAAAaaaaaaAaAaAaCcCcCcCcCcDdDdDdEEEEeeeeEeEeEeEeEeGgGgGgGgHhHhIIIIiiiiIiIiIiIiIiJjKkkLlLlLlLlLlNnNnNnNnnNnOOOOOOooooooOoOoOoRrRrRrSsSsSsSssT"
      def auto_slug
         s = self.to_label.tr(ACCENTS_FROM,ACCENTS_TO).tr(' .,;:?!/\'"()[]{}<>','-').gsub(/&/, 'and').gsub(/-+/,'-').gsub(/(^-|-$)/,'')
        defined?(::Rack::Utils) ? ::Rack::Utils.escape(s) : s
      end
      def to_slug; @doc[model.slug_column]||self.auto_slug; end
      # To param will be deprecated
      # Use a URL like .../<id>/<slug> instead
      def to_param; "#{@doc['_id']}-#{to_label.scan(/\w+/).join('-')}"; end
      def field_id_for(col); "%s-%s-%s" % [id||'new',model.name,col]; end

      # relationships
      def resolve_class(k); k.kind_of?(Class) ? k : Kernel.const_get(k); end
      def parent(k, opts={})
        if k.kind_of?(String)
          key = k
          klass = resolve_class(model.schema[k][:parent_class]) 
        else
          klass = resolve_class(k)
          key = klass.foreign_key_name
        end
        klass.get(@doc[key], opts)
      end
      def slot_children(k, opts={})
        if k.kind_of?(String)
          key = k
          klass = resolve_class(model.schema[k][:children_class]) 
        else
          klass = resolve_class(k)
          key = klass.foreign_key_name(true)
        end
        klass.get_multiple((@doc[key]||[]), opts)
      end
      def first_slot_child(k, opts={})
        if k.kind_of?(String)
          key = k
          klass = resolve_class(model.schema[k][:children_class]) 
        else
          klass = resolve_class(k)
          key = klass.foreign_key_name(true)
        end
        klass.get((@doc[key]||[])[0], opts)
      end
      def children(k,opts={})
        k = resolve_class(k)
        slot_name = opts.delete(:slot_name) || model.foreign_key_name
        k.find({slot_name=>@doc['_id'].to_s}, opts)
      end
      def first_child(k,opts={})
        k = resolve_class(k)
        slot_name = opts.delete(:slot_name) || model.foreign_key_name
        d = k.find_one({slot_name=>@doc['_id'].to_s}, opts)
      end
      def children_count(k,sel={})
        k = resolve_class(k)
        slot_name = sel.delete(:slot_name) || model.foreign_key_name
        k.collection.count({slot_name=>@doc['_id'].to_s}.update(sel))
      end

      # CRUD
      def delete
        before_delete
        model.delete(@doc['_id'])
        after_delete
      end

      # saving and hooks
      def new?; @is_new ||= !@doc.key?('_id'); end
      def update_doc(fields)
        @old_doc = @doc.dup
        @doc.update(fields)
        @is_new = false
        self
      end
      # Getter and setter in one
      def errors_on(col,message=nil)
        message.nil? ? @errors[col] : @errors[col] = (@errors[col]||[]) << message
      end
      def before_delete; @old_doc = @doc.dup; end
      alias before_destroy before_delete
      def after_delete
        model.relationships.each do |k,v|
          Kernel.const_get(k).find({model.foreign_key_name=>@old_doc['_id'].to_s}).each{|m| m.delete} unless v[:independent]
        end
      end
      alias after_destroy after_delete
      def valid?
        before_validation
        validate
        after_validation
        @errors.empty?
      end
      def before_validation
        @errors = {}
        @doc.each do |k,v|
          next unless model.schema.key?(k)
          type = k=='_id' ? :primary_key : model.schema[k][:type]
          fix_method = "fix_type_#{type}"
          if v=='' and type!=:attachment
            default = model.schema[k][:default]
            @doc[k] = default.is_a?(Proc) ? default.call : default
          else
            self.__send__(fix_method, k, v) if self.respond_to?(fix_method)
          end
        end
      end
      def validate; end
      def after_validation; end
      def fix_type_integer(k,v); @doc[k] = v.to_i; end
      def fix_type_price(k,v)
        @doc[k] = v.respond_to?(:to_price_integer) ? v.to_price_integer : v
      end
      def fix_type_boolean(k,v); @doc[k] = (v=='true'||v==true) ? true : false; end
      def fix_type_slug(k,v); @doc[k] = self.auto_slug if v.to_s==''; end
      def fix_type_date(k,v)
        if v.is_a?(String)
          if v[/\d\d\d\d-\d\d-\d\d/]
            @doc[k] =  ::Time.utc(*v.split('-'))
          else
            default = model.schema[k][:default]
            @doc[k] = default.is_a?(Proc) ? default.call : default
          end
        end
      end
      def fix_type_datetime(k,v)
        if v.is_a?(String)
          if v[/\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d/]
            @doc[k] =  ::Time.utc(*v.split(/[-:\s]/))
          else
            default = model.schema[k][:default]
            @doc[k] = default.is_a?(Proc) ? default.call : default
          end
        end
      end
      def fix_type_select(k,v)
        if v.is_a?(Array)
          @doc[k] = v - ['nil']
        end
      end
      def fix_type_children(k,v)
        self.fix_type_select(k,v)
      end

      def save
        return nil unless valid?
        before_save
        if new?
          before_create
          result = model.collection.insert_one(@doc)
          if result.ok? and @doc['_id'].nil?
            @doc['_id'] = result.inserted_id
          end
          after_create
        else
          before_update
          result = model.collection.update_one({'_id'=>@doc['_id']}, @doc)
          after_update
        end
        after_save
        result.ok? ? self : nil
      end
      def before_save; end
      def before_create; end
      def before_update; end
      def after_save; end
      def after_create; @is_new = false; end
      def after_update; end

      # ==========
      # = Cursor =
      # ==========
      module CursorMutation
        # Extend the cursor provided by the Ruby MongoDB driver
        # We must keep the regular cursor
        # so we should extend on demand.
        # Meaning the cursor object should be extended, not the cursor class.
        # @mutant_class should be defined before extending
        #
        # def next
        #   n = super
        #   n.nil? ? nil : @mutant_class.new(n)
        # end
        #
        def each
          super do |doc|
            yield @mutant_class.new(doc)
          end if block_given?
        end
        # legacy
        def each_mutant(&b); each(&b); end
        def each_mutant_with_index(&b); each_with_index(&b); end
      end

    end
  end
end
