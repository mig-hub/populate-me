module PopulateMe
  module DocumentMixins
    module AdminAdapter

      def to_admin_url
        "#{Utils.dasherize_class_name(self.class.name)}/#{id}".sub(/\/$/,'')
      end

      def to_admin_list_item o={}
        {
          class_name: self.class.name,
          id: self.id,
          admin_url: to_admin_url,
          title: to_s,
          local_menu: self.class.relationships.inject([]) do |out,(k,v)|
            unless v[:hidden]
              out << {
                title: "#{v[:label]}",
                href: "#{o[:request].script_name}/list/#{Utils.dasherize_class_name(v[:class_name])}?filter[#{v[:foreign_key]}]=#{self.id}"
              }
              out
            end
          end
        }
      end

      def to_admin_form o={}
        o[:input_name_prefix] ||= 'data'
        class_item = {
          type: :hidden,
          input_name: "#{o[:input_name_prefix]}[_class]",
          input_value: self.class.name,
        }
        self.class.complete_field_options :_class, class_item
        items = self.class.fields.inject([class_item]) do |out,(k,item)|
          item = item.dup
          if item[:form_field]
            outcast k, item, o
            out << item
          end
          out
        end
        {
          template: "template#{'_nested' if o[:nested]}_form",
          page_title: self.new? ? "New #{self.class.to_s_short}" : self.to_s,
          admin_url: self.to_admin_url,
          is_new: self.new?,
          fields: items
        }
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        def admin_get id
          self.cast do
            documents.find{|doc| doc[id_string_key]==id }
          end
        end

        def admin_find o={}
          o[:query] ||= {}
          docs = self.cast{documents}.find_all do |d|
            o[:query].inject(true) do |out,(k,v)|
              out && (d.__send__(k)==v)
            end
          end
          docs.sort!(&@sort_proc) if @sort_proc.is_a?(Proc)
          docs
        end

        def sort_field_for o={}
          filter = o[:params][:filter]
          return nil if !filter.nil?&&filter.size>1
          expected_scope = filter.nil? ? nil : filter.keys[0].to_sym
          f = self.fields.find do |k,v| 
            v[:type]==:position&&v[:scope]==expected_scope
          end
          f.nil? ? nil : f[0]
        end

        def to_admin_list o={}
          o[:params] ||= {}
          unless o[:params][:filter].nil?
            query = o[:params][:filter].inject({}) do |query, (k,v)|
              query[k.to_sym] = self.new.typecast(k,v)
              query
            end
            new_data = Rack::Utils.build_nested_query(data: o[:params][:filter])
          end
          {
            template: 'template_list',
            page_title: self.to_s_short_plural,
            dasherized_class_name: PopulateMe::Utils.dasherize_class_name(self.name),
            new_data: new_data,
            sort_field: self.sort_field_for(o),
            # 'command_plus'=> !self.populate_config[:no_plus],
            # 'command_search'=> !self.populate_config[:no_search],
            items: self.admin_find(query: query).map do |d| 
              d.to_admin_list_item(o) 
            end
          }
        end

      end

    end
  end
end

