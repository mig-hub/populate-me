module PopulateMe
  module DocumentMixins
    module Callbacks

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

      def ensure_id
        if self.id.nil?
          self.id = Utils::generate_random_id
        end
        self
      end

      def ensure_not_new; self._is_new = false; end

      def ensure_delete_related
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

      def ensure_delete_attachments
        self.class.fields.each do |k,v|
          if v[:type]==:attachment
            self.attachment(k).delete
          end
        end
      end

      def ensure_new; self._is_new = true; end

      def self.included(base)
        base.extend(ClassMethods)
        base.class_eval do
          [:save,:create,:update,:delete].each do |cb|
            before cb, :recurse_callback
            after cb, :recurse_callback
          end
          before :create, :ensure_id
          after :create, :ensure_not_new
          after :save, :snapshot
          before :delete, :ensure_delete_related
          before :delete, :ensure_delete_attachments
          after :delete, :ensure_new
        end
      end

      module ClassMethods

        attr_accessor :callbacks

        def register_callback name, item=nil, options={}, &block
          name = name.to_sym
          if block_given?
            options = item || {}
            item = block
          end
          self.callbacks ||= {}
          self.callbacks[name] ||= []
          if options[:prepend]
            self.callbacks[name].unshift item
          else
            self.callbacks[name] << item
          end
        end

        def before name, item=nil, options={}, &block
          register_callback "before_#{name}", item, options, &block
        end

        def after name, item=nil, options={}, &block
          register_callback "after_#{name}", item, options, &block
        end

      end

    end
  end
end

