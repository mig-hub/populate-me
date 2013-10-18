# encoding: utf-8
module PopulateMe
  module Mongo
    module Mutation
  
      # Most important MongoDB module
      # It defines the ODM
  
      def self.included(weak)
        weak.extend(MutateClass)
        weak.db = DB if defined?(DB)
        weak.schema = BSON::OrderedHash.new
        weak.relationships = BSON::OrderedHash.new
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
        def ref(id)
          if id.is_a?(String)&&BSON::ObjectId.legal?(id)
            id = BSON::ObjectId.from_string(id)
          elsif !id.is_a?(BSON::ObjectId)
            id = ''
          end
          {'_id'=>id}
        end
        def find(selector={},opts={})
          selector.update(opts.delete(:selector)||{})
          opts = {:sort=>self.sorting_order}.update(opts)
          collection.find(selector,opts).extend(CursorMutation)
        end
        def find_one(spec_or_object_id=nil,opts={})
          spec_or_object_id.nil? ? spec_or_object_id = opts.delete(:selector) : spec_or_object_id.update(opts.delete(:selector)||{})
          opts = {:sort=>self.sorting_order}.update(opts)
          item = collection.find_one(spec_or_object_id,opts)
          item.nil? ? nil : self.new(item)
        end
        def count(opts={}); collection.count(opts); end

        def sorting_order
          @sorting_order ||= if @schema.key?('position')&&!@schema['position'][:scope].nil?
            [[@schema['position'][:scope], :asc], ['position', :asc]]
          elsif @schema.key?('position')
            [['position', :asc],['_id', :asc]]
          else
            ['_id', :asc]
          end
        end

        def sort(id_list)
          id_list.each_with_index do |id, position|
            collection.update(ref(id), {'$set' => {'position'=>position}})
          end
        end

        # CRUD
        def get(id, opts={}); doc = collection.find_one(ref(id), opts); doc.nil? ? nil : self.new(doc); end
        def delete(id); collection.remove(ref(id)); end

        def is_unique(doc={})
          return unless collection.count==0
          doc = {'_id'=>BSON::ObjectId('000000000000000000000000')}.update(doc)
          d = self.new
          d.doc.update(doc)
          d.save 
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
        ids = (@doc[key]||[]).map{|i| BSON::ObjectId.from_string(i) }
        selector = {'_id'=>{'$in'=>ids}}
        sort_proc = proc{ |a,b| ids.index(a['_id'])<=>ids.index(b['_id']) }
        klass.find(selector, opts).to_a.sort(&sort_proc)
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
        k.collection.count(:query => {slot_name=>@doc['_id'].to_s}.update(sel))
      end

      # CRUD
      def delete
        before_delete
        model.delete(@doc['_id'])
        after_delete
      end

      # saving and hooks
      def new?; @is_new ||= !@doc.key?('_id'); end
      def update_doc(fields); @old_doc = @doc.dup; @doc.update(fields); @is_new = false; self; end
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
          if v==''
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

      def save
        return nil unless valid?
        before_save
        if new?
          before_create
          id = model.collection.insert(@doc)
          @doc['_id'] = id
          after_create
        else
          before_update
          id = model.collection.update({'_id'=>@doc['_id']}, @doc)
          after_update
        end
        after_save
        id.nil? ? nil : self
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
        def self.extended(into)
          into.set_mutant_class
        end
        def set_mutant_class
          @mutant_class = Kernel.const_get(collection.name)
        end
        def next
          n = super
          n.nil? ? nil : @mutant_class.new(n)
        end
        # legacy
        def each_mutant(&b); each(&b); end
        def each_mutant_with_index(&b); each_with_index(&b); end
      end

    end
  end
end
