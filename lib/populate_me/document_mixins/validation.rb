module PopulateMe
  module DocumentMixins
    module Validation

      attr_accessor :_errors
      
      def errors; self._errors; end

      def error_on k,v 
        self._errors[k] = (self._errors[k]||[]) << v
        self
      end

      def valid?
        self._errors = {}
        exec_callback :before_validate
        validate
        exec_callback :after_validate
        nested_docs.reduce self._errors.empty? do |result,d|
          result &= d.valid?
        end
      end

      def validate; end

      def error_report
        report = self._errors.dup || {}
        persistent_instance_variables.each do |var|
          value = instance_variable_get var
          if is_nested_docs?(value)
            k = var[1..-1].to_sym
            report[k] = []
            value.each do |d|
              report[k] << d.error_report
            end
          end
        end
        report
      end

    end
  end
end

