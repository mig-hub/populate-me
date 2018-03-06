module PopulateMe
  module DocumentMixins
    module Schema

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        attr_writer :fields
        attr_accessor :label_field

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
          WebUtils.ensure_key! o, :type, :string
          WebUtils.ensure_key! o, :form_field, ![:id,:position].include?(o[:type])
          o[:wrap] = false unless o[:form_field]
          WebUtils.ensure_key! o, :wrap, ![:hidden,:list].include?(o[:type])
          WebUtils.ensure_key! o, :label, WebUtils.label_for_field(name)
          if o[:type]==:attachment
            WebUtils.ensure_key! o, :class_name, settings.default_attachment_class
            raise MissingAttachmentClassError, "No attachment class was provided for the #{self.name} field: #{name}" if o[:class_name].nil?
            o[:class_name] = o[:class_name].name unless o[:class_name].is_a?(String)
          end
          if o[:type]==:list
            o[:class_name] = WebUtils.guess_related_class_name(self.name,o[:class_name]||name)
            o[:dasherized_class_name] = WebUtils.dasherize_class_name o[:class_name]
          else
            WebUtils.ensure_key! o, :input_attributes, {}
            o[:input_attributes][:type] = :hidden if o[:type]==:hidden
            unless o[:type]==:text
              WebUtils.ensure_key! o[:input_attributes], :type, :text
            end
          end
        end

        def set_id_field
          field :id, {type: :id}
        end

        def position_field o={}
          name = o[:name]||:position
          o[:type] = :position
          field name, o
          sort_by name, direction: (o[:direction]||:asc)
        end

        def label sym # sets the label_field
          @label_field = sym.to_sym
        end

        def label_field
          @label_field || self.fields.keys[1]
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

        def relationships; @relationships ||= {}; end

        def relationship name, o={}
          o[:class_name] = WebUtils.guess_related_class_name(self.name,o[:class_name]||name)
          WebUtils.ensure_key! o, :label, name.to_s.gsub('_',' ').capitalize
          WebUtils.ensure_key! o, :foreign_key, "#{WebUtils.dasherize_class_name(self.name).gsub('-','_')}_id"
          o[:foreign_key] = o[:foreign_key].to_sym
          WebUtils.ensure_key! o, :dependent, true
          self.relationships[name] = o

          define_method(name) do
            var = "@cached_#{name}"
            instance_variable_set(var, instance_variable_get(var)||WebUtils.resolve_class_name(o[:class_name]).admin_find(query: {o[:foreign_key]=>self.id}))
          end

          define_method("#{name}_first".to_sym) do
            var = "@cached_#{name}_first"
            instance_variable_set(var, instance_variable_get(var)||WebUtils.resolve_class_name(o[:class_name]).admin_find_first(query: {o[:foreign_key]=>self.id}))
          end
        end

        def to_select_options o={}
          proc do
            items = self.admin_find(query: (o[:query]||{}), fields: [self.id_string_key, self.label_field])
            output = items.sort_by do |i|
              i.to_s.downcase
            end.map do |i|
              [i.to_s, i.id]
            end
            output.unshift(['?','']) if o[:allow_empty]
            output
          end
        end

      end

    end
  end
end

