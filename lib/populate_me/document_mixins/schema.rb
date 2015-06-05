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
          Utils.ensure_key o, :type, :string
          Utils.ensure_key o, :form_field, ![:id,:position].include?(o[:type])
          o[:wrap] = false unless o[:form_field]
          Utils.ensure_key o, :wrap, ![:hidden,:list].include?(o[:type])
          Utils.ensure_key o, :label, Utils.label_for_field(name)
          if o[:type]==:attachment
            Utils.ensure_key o, :class_name, settings.default_attachment_class
            raise MissingAttachmentClassError, "No attachment class was provided for the #{self.name} field: #{name}" if o[:class_name].nil?
            o[:class_name] = o[:class_name].name unless o[:class_name].is_a?(String)
          end
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
          o[:class_name] = Utils.guess_related_class_name(self.name,o[:class_name]||name)
          Utils.ensure_key o, :label, name.to_s.capitalize
          Utils.ensure_key o, :foreign_key, "#{Utils.dasherize_class_name(self.name).gsub('-','_')}_id"
          o[:foreign_key] = o[:foreign_key].to_sym
          Utils.ensure_key o, :dependent, true
          self.relationships[name] = o
        end

      end

    end
  end
end

