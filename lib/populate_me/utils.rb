# encoding: utf-8

require 'rack/utils'

module PopulateMe
  module Utils

    extend Rack::Utils

    def blank?(s)
      s.to_s.strip==''
    end
    module_function :blank?

    def dasherize_class_name(s)
      s.gsub(/[A-Z]/){|s|"-#{s.downcase}"}[1..-1].gsub('::','-')
    end
    module_function :dasherize_class_name

    def undasherize_class_name(s)
      s.capitalize.gsub(/\-([a-z])/){|s|$1.upcase}.gsub('-','::')
    end
    module_function :undasherize_class_name

    def resolve_class_name(s,context=Kernel)
      return nil if blank?(s)
      current, *payload = s.split('::')
      return nil unless context.const_defined?(current)
      const = context.const_get(current)
      if payload.empty?
        const
      else
        resolve_class_name(payload.join('::'),const)
      end
    end
    module_function :resolve_class_name

    def resolve_dasherized_class_name(s)
      return nil if blank?(s)
      resolve_class_name(undasherize_class_name(s)) 
    end
    module_function :resolve_dasherized_class_name

    ACCENTS_FROM = 
      "ÀÁÂÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđÈÉÊËèéêëĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀŁłÑñŃńŅņŇňŉŊŋÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞ"
    ACCENTS_TO = 
      "AAAAAAaaaaaaAaAaAaCcCcCcCcCcDdDdDdEEEEeeeeEeEeEeEeEeGgGgGgGgHhHhIIIIiiiiIiIiIiIiIiJjKkkLlLlLlLlLlNnNnNnNnnNnOOOOOOooooooOoOoOoRrRrRrSsSsSsSssT"
    def slugify(s,force_lower=true)
      s = s.to_s.tr(ACCENTS_FROM,ACCENTS_TO).tr(' .,;:?!/\'"()[]{}<>','-').gsub(/&/, 'and').gsub(/-+/,'-').gsub(/(^-|-$)/,'')
      s = s.downcase if force_lower
      escape(s)
    end
    module_function :slugify

    def each_stub(obj,&block)
      obj.each_with_index do |(k,v),i|
        value = v || k
        if value.is_a?(Hash) || value.is_a?(Array)
          each_stub(value,&block)
        else
          block.call(obj, (v.nil? ? i : k), value)
        end
      end
    end
    module_function :each_stub

    def automatic_typecast(obj)
      return obj unless obj.is_a?(String)
      if obj=='true'
        true
      elsif obj=='false'
        false
      elsif obj==''
        nil
      end
    end
    module_function :automatic_typecast

    ID_CHARS = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    ID_SIZE = 16
    def generate_random_id size=ID_SIZE
      id = ''
      size.times{id << ID_CHARS[rand(ID_CHARS.size)]} 
      id
    end
    module_function :generate_random_id

  end
end

