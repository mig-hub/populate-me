module PopulateMe
  module DocumentMixins
    module Outcasting

      # This module prepares the field for being send to the Admin API
      # and build the form.
      # It compiles the value and all other info in a hash.
      # Therefore, it is a complement to the AdminAdapter module.

      def outcast field, item, o={}
        item = item.dup
        item[:input_name] = "#{o[:input_name_prefix]}[#{item[:field_name]}]"
        unless item[:type]==:list
          WebUtils.ensure_key! item, :input_value, self.__send__(field)
        end
        meth = "outcast_#{item[:type]}".to_sym
        if respond_to?(meth)
          __send__(meth, field, item, o) 
        else
          item
        end
      end

      def outcast_string field, item, o={}
        if item.key? :autocomplete
          item = item.dup
          item[:autocomplete] = WebUtils.deep_copy(WebUtils.get_value(item[:autocomplete],self))
        end
        item
      end

      def outcast_list field, item, o={}
        item = item.dup
        item[:items] = self.__send__(field).map do |nested|
         nested.to_admin_form(o.merge(input_name_prefix: item[:input_name]+'[]'))
        end
        item
      end

      def outcast_select field, item, o={}
        item = item.dup
        unless item[:select_options].nil?
          if item[:multiple]==true
            item[:input_name] = item[:input_name]+'[]'
          end
          opts = WebUtils.deep_copy(WebUtils.get_value(item[:select_options],self))
          opts.map! do |opt|
            if opt.is_a?(String)||opt.is_a?(Symbol)
              opt = [opt.to_s.capitalize,opt]
            end
            if opt.is_a?(Array)
              opt = {description: opt[0].to_s, value: opt[1].to_s}
            end
            if item[:input_value].respond_to?(:include?)
              opt[:selected] = true if item[:input_value].include?(opt[:value])
            else
              opt[:selected] = true if item[:input_value]==opt[:value]
            end
            opt
          end
          if item[:multiple]
            (item[:input_value]||[]).reverse.each do |iv|
              opt = opts.find{|opt| opt[:value]==iv }
              opts.unshift(opts.delete(opt)) unless opt.nil?
            end
          end
          item[:select_options] = opts
          item
        else
          item
        end
      end

      def outcast_attachment field, item, o={}
        item = item.dup
        item[:url] = self.attachment(field).url
        item[:multiple] = (self.new? and self.class.batch_field == field)
        item
      end

      def outcast_price field, item, o={}
        item = item.dup
        if item[:input_value].is_a?(Integer)
          item[:input_value] = WebUtils.display_price item[:input_value]
        end
        item
      end

    end
  end
end

