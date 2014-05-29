module PopulateMe
  module Utils

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

  end
end

