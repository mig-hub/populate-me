# encoding: utf-8
module PopulateMe
  module Mongo
    module Crushyform
  
      # This module adds to mutated models the ability
      # to build forms using the settings of the schema
  
      def self.included(base)
        base.extend(ClassMethods)
      end
  
      module ClassMethods
    
        def crushyform_types
          @crushyform_types ||= {
            :none => proc{''},
            :string => proc do |m,c,o|
              if o[:autocompleted]
                values = o[:autocomplete_options] || m.class.collection.distinct(c)
                js = <<-EOJS
                <script type="text/javascript" charset="utf-8">
                  $(function(){
                    $( "##{m.field_id_for(c)}" ).autocomplete({source: ["#{values.map{|v|v.to_s.gsub(/"/,'')}.join('","')}"]});
                  });
                </script>
                EOJS
              end
              tag = "<input type='%s' name='%s' value=\"%s\" id='%s' class='%s' %s />%s\n" % [o[:input_type]||'text', o[:input_name], o[:input_value], m.field_id_for(c), o[:input_class], o[:required]&&'required', o[:required]]
              "#{tag}#{js}"
            end,
            :slug => proc do |m,c,o|
              crushyform_types[:string].call(m,c,o)
            end,
            :price => proc do |m,c,o|
              value = o[:input_value].to_price_string if o[:input_value].respond_to?(:to_price_string)
              "<input type='%s' name='%s' value=\"%s\" id='%s' class='%s' %s />%s\n" % [o[:input_type]||'text', o[:input_name], value, m.field_id_for(c), o[:input_class], o[:required]&&'required', o[:required]]
            end,
            :boolean => proc do |m,c,o|
              crushid = m.field_id_for(c)
              checked = 'checked' if o[:input_value]
              out = "<input type='hidden' name='%s' value='false' id='%s-off' />\n"
              out += "<input type='checkbox' name='%s' value='true' id='%s' class='%s' %s />\n"
              out % [o[:input_name], crushid, o[:input_name], crushid, o[:input_class], checked]
            end,
            :text => proc do |m,c,o|
              "<textarea name='%s' id='%s' class='%s' %s>%s</textarea>%s\n" % [o[:input_name], m.field_id_for(c), o[:input_class], o[:required]&&'required', o[:input_value], o[:required]]
            end,
            :date => proc do |m,c,o|
              o[:input_value] = o[:input_value].strftime("%Y-%m-%d") if o[:input_value].respond_to?(:strftime)
              o[:required] = "%s Format: yyyy-mm-dd" % [o[:required]]
              crushyform_types[:string].call(m,c,o)
            end,
            :time => proc do |m,c,o|
              o[:input_value] = o[:input_value].strftime("%T") if o[:input_value].respond_to?(:strftime)
              o[:required] = "%s Format: hh:mm:ss" % [o[:required]]
              crushyform_types[:string].call(m,c,o)
            end,
            :datetime => proc do |m,c,o|
              o[:input_value] = o[:input_value].strftime("%Y-%m-%d %T") if o[:input_value].respond_to?(:strftime)
              o[:required] = "%s Format: yyyy-mm-dd hh:mm:ss" % [o[:required]]
              crushyform_types[:string].call(m,c,o)
            end,
            :parent => proc do |m,c,o|
              parent_class = o[:parent_class].nil? ? Kernel.const_get(c.sub(/^id_/, '')) : m.resolve_class(o[:parent_class])
              option_list = parent_class.to_dropdown(o[:input_value])
              "<select name='%s' id='%s' class='%s'>%s</select>\n" % [o[:input_name], m.field_id_for(c), o[:input_class], option_list]
            end,
            :children => proc do |m,c,o|
              children_class = o[:children_class].nil? ? Kernel.const_get(c.sub(/^ids_/, '')) : m.resolve_class(o[:children_class])
              opts = o.update({
                :multiple=>true,
                :select_options=>children_class.dropdown_cache
              })
              @crushyform_types[:select].call(m,c,opts)
            end,
            :attachment => proc do |m,c,o|
              deleter = "<input type='checkbox' name='#{o[:input_name]}' class='deleter' value='nil' /> Delete this file<br />" unless m.doc[c].nil?
              "%s%s<input type='file' name='%s' id='%s' class='%s' />%s\n" % [m.to_thumb(c), deleter, o[:input_name], m.field_id_for(c), o[:input_class], o[:required]]
            end,
            :select => proc do |m,c,o|
              # starter ensures it sends something when multiple is empty
              # Otherwise it is not sent and therefore not updated
              starter = if o[:multiple]
                          "<input type='hidden' name='%s[]' value='nil' class='multiple-select-starter' />\n" % [o[:input_name]]
                        else
                          ''
                        end
              out = "%s<select name='%s%s' id='%s' class='%s' %s title='-- Select --'>\n" % [starter, o[:input_name], ('[]' if o[:multiple]), m.field_id_for(c), o[:input_class], ('multiple' if o[:multiple])]
              o[:select_options] = m.__send__(o[:select_options]) unless o[:select_options].kind_of?(Array)
              select_options = o[:select_options].dup
              if (o[:multiple] && !o[:input_value].nil? && o[:input_value].size>1)
                # This if is for having the selected options ordered (they can be ordered with asm select)
                o[:input_value].reverse.each do |v|
                  elem = select_options.find{|x| x==v||(x||[])[1]==v }
                  select_options.unshift(select_options.delete(elem)) unless elem.nil?
                end
              end
              if select_options.kind_of?(Array)
                select_options.each do |op|
                  key,val = op.kind_of?(Array) ? [op[0],op[1]] : [op,op]
                  if key==:optgroup
                    out << "<optgroup label='%s'>\n" % [val]
                  elsif key==:closegroup
                    out << "</optgroup>\n"
                  else
                    # Array case is for multiple select
                    selected = 'selected' if (val==o[:input_value] || (o[:input_value].kind_of?(Array)&&o[:input_value].include?(val)))
                    out << "<option value='%s' %s>%s</option>\n" % [val,selected,key]
                  end
                end
              end
              out << "</select>%s\n" % [o[:required]]
            end,
            :string_list => proc do |m,c,o|
              if o[:autocompleted]
                values = o[:autocomplete_options] || m.class.collection.distinct(c)
                js = <<-EOJS
                <script type="text/javascript" charset="utf-8">
                  $(function(){
                    $( "##{m.field_id_for(c)}" )
                    .bind( "keydown", function( event ) {
                      if ( event.keyCode === $.ui.keyCode.TAB &&
                      $( this ).data( "autocomplete" ).menu.active ) {
                        event.preventDefault();
                      }
                    })
                    .autocomplete({
                      minLength: 0,
                      source: function( request, response ) {
                        response($.ui.autocomplete.filter(["#{values.map{|v|v.to_s.gsub(/"/,'')}.join('","')}"], request.term.split(/,\s*/).pop()));
                      },
                      focus: function() { return false; },
                      select: function( event, ui ) {
                        var terms = this.value.split(/,\s*/);
                        terms.pop();
                        terms.push(ui.item.value);
                        terms.push("");
                        this.value = terms.join( ", " );
                        return false;
                      }
                    });
                  });
                </script>
                EOJS
                o[:autocompleted] = false # reset so that it does not autocomplete for :string type below
              end
              tag = @crushyform_types[:string].call(m,c,o.update({:input_value=>(o[:input_value]||[]).join(',')}))
              "#{tag}#{js}"
            end,
            :permalink => proc do |instance, column_name, options|
              values = "<option value=''>Or Browse the list</option>\n"
              tag = @crushyform_types[:string].call(instance, column_name, options)
              return tag if options[:permalink_classes].nil?
              options[:permalink_classes].each do |sym|
                c = Kernel.const_get sym
                entries = c.find
                unless entries.count==0
                  values << "<optgroup label='#{c.human_name}'>\n"
                  entries.each do |e|
                    values << "<option value='#{e.permalink}' #{'selected' if e.permalink==options[:input_value]}>#{e.to_label}</option>\n"
                  end
                  values << "</optgroup>\n"
                end
              end
              "#{tag}<br />\n<select name='__permalink' class='permalink-dropdown'>\n#{values}</select>\n"
            end
          }
        end
    
        # What represents a required field
        # Can be overriden
        def crushyfield_required; "<span class='crushyfield-required'> *</span>"; end
        # Stolen from ERB
        def html_escape(s)
          s.to_s.gsub(/&/, "&amp;").gsub(/\"/, "&quot;").gsub(/>/, "&gt;").gsub(/</, "&lt;")
        end
        # Cache dropdown options for children classes to use  
        # Meant to be reseted each time an entry is created, updated or destroyed  
        # So it is only rebuild once required after the list has changed  
        # Maintaining an array and not rebuilding it all might be faster  
        # But it will not happen much so that it is fairly acceptable  
        def to_dropdown(selection=nil, nil_name='** UNDEFINED **')
          dropdown_cache.inject("<option value=''>#{nil_name}</option>\n") do |out, row|
            selected = 'selected' if row[1]==selection
            "%s%s%s%s" % [out, row[2], selected, row[3]]
          end
        end
        def dropdown_cache
          @dropdown_cache ||= self.find({},:fields=>['_id',label_column]).inject([]) do |out,row|
            out.push([row.to_label, row.id.to_s, "<option value='#{row.id}' ", ">#{row.to_label}</option>\n"])
          end
        end
        def reset_dropdown_cache; @dropdown_cache = nil; end
    
      end
  
      # Instance Methods

      def crushyform(columns=model.schema.keys, action=nil, meth='POST')
        columns.delete('_id')
        fields = columns.inject(""){|out,c|out.force_encoding('utf-8')+crushyfield(c).force_encoding('utf-8')}
        enctype = fields.match(/type='file'/) ? "enctype='multipart/form-data'" : ''
        action.nil? ? fields : "<form action='%s' method='%s' %s>%s</form>\n" % [action, meth, enctype, fields]
      end
      # crushyfield is crushyinput but with label+error
      def crushyfield(col, o={})
        return '' if (o[:type]==:none || model.schema[col][:type]==:none)
        return crushyinput(col,o) if (o[:input_type]=='hidden' || model.schema[col][:input_type]=='hidden')
        default_field_name = col[/^id_/] ? Kernel.const_get(col.sub(/^id_/, '')).human_name : col.tr('_', ' ').capitalize
        field_name = o[:name] || model.schema[col][:name] || default_field_name
        error_list = errors_on(col).map{|e|" - #{e}"} if !errors_on(col).nil?
        "<p class='crushyfield %s'><label for='%s'>%s</label><span class='crushyfield-error-list'>%s</span><br />\n%s</p>\n" % [error_list&&'crushyfield-error', field_id_for(col), field_name, error_list, crushyinput(col, o)]
      end
      def crushyinput(col, o={})
        o = model.schema[col].dup.update(o)
        o[:input_name] ||= "model[#{col}]"
        o[:input_value] = o[:input_value].nil? ? self[col] : o[:input_value]
        o[:input_value] = model.html_escape(o[:input_value]) if (o[:input_value].is_a?(String) && o[:html_escape]!=false)
        o[:required] = o[:required]==true ? model.crushyfield_required : o[:required]
        crushyform_type = model.crushyform_types[o[:type]] || model.crushyform_types[:string]
        crushyform_type.call(self,col,o)
      end
      # Provide a thumbnail for the column
      def to_thumb(c)
        current = @doc[c]
        if current.respond_to?(:[])
          "<img src='/gridfs/#{@doc[c]['stash_thumb_gif']}' width='100' onerror=\"this.style.display='none'\" alt='Thumb' />\n"
        end
      end
      # Reset dropdowns on hooks
      def after_save; model.reset_dropdown_cache; super; end
      def after_delete; model.reset_dropdown_cache; super; end
      # Fix types
      def fix_type_string_list(k,v); @doc[k] = v.to_s.strip.split(/\s*,\s*/).compact if v.is_a?(String); end

  
    end
  end
end
