require "populate_me/utils"

module PopulateMe
  class Builder
    attr_accessor :to_s

    def self.create(&block); self.new(false,&block).to_s; end
    def self.create_here(&block); self.new(true,&block).to_s; end

    def initialize outer_scope=false, &block
      @to_s = ""
      return self unless block_given?
      unless outer_scope
        instance_eval(&block)
      else
        block.call(self)
      end
      self
    end

    def method_missing(meth, args={}, &block); tag(meth, args, &block); end

    def tag name, attributes={}
      @to_s << "<#{name}"
      if attributes.kind_of?(String)
        @to_s << ' ' << attributes
      else
        @to_s << attributes.delete_if{|k,v| v.nil? or v==false }.map{|(k,v)| " #{k}='#{Rack::Utils.escape_html(v)}'" }.join
      end
      if block_given?
        @to_s << ">"
        text = yield
        @to_s << text.to_str if text != @to_s and text.respond_to?(:to_str)
        @to_s << "</#{name}>"
      else
        @to_s << ' />'
      end
    end

    # Override Kernel methods
    
    def p(args={}, &block); tag(:p, args, &block); end
    def select(args={}, &block); tag(:select, args, &block); end
    
    # Basic helpers

    def write(s=''); @to_s << s; end
    def doctype; write "<!DOCTYPE html>\n"; end
    def comment(s=''); write "\n<!-- #{s} -->\n"; end

    # Form helpers

    def input_for obj, field, o={}
      o = obj.class.fields[field].merge(o) if obj.class.respond_to?(:fields)
      return if o[:form_field]==false
      o[:input_name] ||= "#{o[:input_name_prefix]||'data'}[#{field}]"
      o[:input_value] ||= obj.__send__(field)
      o[:input_value] = Rack::Utils.escape_html(o[:input_value]) if (o[:input_value].is_a?(String) && o[:html_escape]!=false)
      o[:type] ||= :string
      type_method = "#{o[:type]}_input_for"
      type_method = 'string_input_for' unless self.respond_to?(type_method)
      return __send__(type_method,obj,field,o) if (o[:wrap_input]==false||o[:type]==:hidden)
      div do
        label { field.to_s }
        br
        __send__(type_method,obj,field,o)
      end
    end
    def string_input_for obj, field, o={}
      attributes = { 
        type: :text, name: o[:input_name], 
        value: o[:input_value], required: o[:required]
      }
      attributes = attributes.merge(o[:input_attributes]) unless o[:input_attributes].nil?
      input(attributes)
    end
    def text_input_for obj, field, o={}
      textarea(name: o[:input_name], required: o[:required]) { o[:input_value] }
    end
    def boolean_input_for obj, field, o={}
      input(type: :hidden, name: o[:input_name], value: 'false')
      input(type: :checkbox, name: o[:input_name], value: 'true', checked: o[:input_value])
    end
    def select_input_for obj, field, o={}
      # o[:input_name] << '[]' if o[:multiple]
      select(name: o[:input_name], multiple: o[:multiple]) do
        o[:select_options] = obj.__send__(o[:select_options]) if o[:select_options].is_a?(Symbol)
        select_options = o[:select_options].dup
        if select_options.is_a?(Array)
          select_options.each do |op|
            key,val = op.is_a?(Array) ? [op[0],op[1]] : [op,op]
            selected = (val==o[:input_value] || (o[:input_value].is_a?(Array)&&o[:input_value].include?(val))) 
            option(value: val, selected: selected) { key.to_s }
          end
        end
      end
    end
    def attachment_input_for obj, field, o={}
      input(type: :checkbox, name: o[:input_name], value: :nil) { 'Delete this file' }
      br
      input(type: :file, name: o[:input_name])
    end

  end
end

