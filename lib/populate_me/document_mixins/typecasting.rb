module PopulateMe
  module DocumentMixins
    module Typecasting

      # This module deals with typecasting the fields
      # when they are received as strings,
      # generally from a form or a csv file

      def typecast k, v
        unless self.class.fields.key?(k)
          return WebUtils.automatic_typecast(v) 
        end
        f = self.class.fields[k].dup
        meth = "typecast_#{f[:type]}".to_sym
        unless respond_to? meth
          return WebUtils.automatic_typecast(v, [f[:type],:nil])
        end
        __send__ meth, k, v
      end

      def typecast_integer k, v
        v.to_i
      end

      def typecast_price k, v
        return nil if WebUtils.blank?(v)
        WebUtils.parse_price(v)
      end

      def typecast_select k, v
        if v.is_a?(Array)
          v.reject{|str| str=='nil' }
        else
          v
        end
      end

      def typecast_date k, v
        if v[/\d\d(\/|-)\d\d(\/|-)\d\d\d\d/]
          Date.parse v
        elsif v[/\d\d\d\d(\/|-)\d\d(\/|-)\d\d/]
          Date.parse v
        else
          nil
        end
      end

      def typecast_datetime k, v
        if v[/\d\d(\/|-)\d\d(\/|-)\d\d\d\d \d\d?:\d\d?:\d\d?/]
          d,m,y,h,min,s = v.split(/[-:\s\/]/)
          Time.utc(y,m,d,h,min,s)
        else
          nil
        end
      end

      def typecast_attachment k, v
        attached = self.attachment k
        if WebUtils.blank? v
          attached.delete_all
          return nil
        elsif v.is_a?(Hash)&&v.key?(:tempfile)
          return attached.create v
        end
      end

    end
  end
end

