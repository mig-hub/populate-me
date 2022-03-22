module PopulateMe
  module DocumentMixins
    module AdminAdapter

      def to_admin_url
        "#{WebUtils.dasherize_class_name(self.class.name)}/#{id}".sub(/\/$/,'')
      end

      def admin_image_url
        thefield = self.class.admin_image_field
        return nil if thefield.nil?
        self.attachment(thefield).url(:populate_me_thumb)
      end

      def to_admin_list_item o={}
        {
          class_name: self.class.name,
          id: self.id.to_s,
          admin_url: to_admin_url,
          title: WebUtils.truncate(to_s, 60),
          image_url: admin_image_url,
          local_menu: self.class.relationships.inject([]) do |out,(k,v)|
            if not v[:hidden] and self.relationship_applicable?(k)
              out << {
                title: "#{v[:label]}",
                href: "#{o[:request].script_name}/list/#{WebUtils.dasherize_class_name(v[:class_name])}?filter[#{v[:foreign_key]}]=#{self.id}",
                new_page: false 
              }
            end
            out
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
          if item[:form_field] and self.field_applicable?(k)
            out << outcast(k, item, o)
          end
          out
        end
        page_title = self.new? ? "New #{self.class.to_s_short}" : self.to_s
        # page_title << " (#{self.polymorphic_type})" if self.class.polymorphic?
        batch_field_item = items.find do |item|
          item[:field_name] == self.class.batch_field
        end
        {
          template: "template#{'_nested' if o[:nested]}_form",
          page_title: page_title,
          admin_url: self.to_admin_url,
          is_new: self.new?,
          polymorphic_type: self.class.polymorphic? ? self.polymorphic_type : nil,
          batch_field: (not self.new? or batch_field_item.nil?) ? nil : batch_field_item[:input_name],
          fields: items
        }
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        def admin_image_field
          res = self.fields.find do |k,v|
            if v[:type]==:attachment and !v[:variations].nil?
              v[:variations].any?{|var|var.name==:populate_me_thumb}
            else
              false
            end
          end
          res.nil? ? nil : res[0]
        end

        def admin_get id
          return self.admin_get_multiple(id) if id.is_a?(Array)
          self.cast do
            documents.find{|doc| doc[id_string_key] == id }
          end
        end

        def admin_get_multiple ids, o={sort: nil}
          self.admin_find(o.merge(query: {id_string_key => {'$in' => ids.uniq.compact}}))
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

        def admin_find_first o={}
          self.admin_find(o)[0]
        end

        def admin_distinct field, o={}
          self.admin_find(o).map{|d| d.__send__ field}.compact.uniq
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
            query = o[:params][:filter].inject({}) do |q, (k,v)|
              q[k.to_sym] = self.new.typecast(k,v)
              q
            end
            new_data = Rack::Utils.build_nested_query(data: o[:params][:filter])
          end
          items = self.admin_find(query: query)
          {
            template: 'template_list',
            grid_view: self.settings[:grid_view]==true,
            page_title: self.to_s_short_plural,
            dasherized_class_name: WebUtils.dasherize_class_name(self.name),
            new_data: new_data,
            is_polymorphic: self.polymorphic?,
            polymorphic_type_values: self.polymorphic? ? self.fields[:polymorphic_type][:values] : nil,
            sort_field: self.sort_field_for(o),
            # 'command_plus'=> !self.populate_config[:no_plus],
            # 'command_search'=> !self.populate_config[:no_search],
            items: items.map do |d| 
              d.to_admin_list_item(o) 
            end
          }
        end

      end

    end
  end
end

