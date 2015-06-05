module PopulateMe
  module DocumentMixins
    module Outcasting

      # This module prepares the field for being send to the Admin API
      # and build the form.
      # It compiles the value and all other info in a hash.
      # Therefore, it is a complement to the AdminAdapter module.

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

      def outcast_attachment field, item, o={}
        item[:url] = self.attachment(field).url
      end

    end
  end
end

