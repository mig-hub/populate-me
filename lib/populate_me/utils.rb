# encoding: utf-8

require 'rack/utils'

module PopulateMe
  module Utils

    extend Rack::Utils

    def dasherize_class_name(s)
      s.gsub(/[A-Z]/){|s|"-#{s.downcase}"}[1..-1]
    end
    module_function :dasherize_class_name

    def undasherize_class_name(s)
      s.capitalize.gsub(/\-([a-z])/){|s|$1.upcase}
    end
    module_function :undasherize_class_name

    def blank?(s)
      s.to_s.strip==''
    end
    module_function :blank?

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

  end
end

