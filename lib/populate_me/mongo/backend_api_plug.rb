module PopulateMe
  module Mongo
    module BackendApiPlug
  
      # This module adds a layer between the backend API and the models.
      # It is legacy code and could probably be removed,
      # but in a way it makes it easier to plug something else than MongoDB.
      # I'll keep it and see.
  
      def self.included(base)
        base.extend(ClassMethods)
      end
  
      module ClassMethods
    	  def backend_get(id); get(id=='unique' ? '000000000000000000000000' : id); end
    		def backend_post(doc=nil); inst = new(doc); inst.is_new = true; inst; end
    	end
	
    	# Instance Methods

    	def backend_delete; delete; end
    	def backend_put(fields); update_doc(fields); end
    	def backend_values; @doc; end
    	def backend_save?; !save.nil?; end
      def backend_form(url, cols=nil, opts={})
        cols ||= default_backend_columns
        if block_given?
          fields_list = ''
          yield(fields_list)
        else
          fields_list = respond_to?(:crushyform) ? crushyform(cols) : backend_fields(cols)
        end
        o = "<form action='#{url}' method='POST' #{"enctype='multipart/form-data'" if fields_list.match(/type='file'/)} class='backend-form'>\n"
        #o << backend_form_title unless block_given?
        o << fields_list
        opts[:method] = 'PUT' if (opts[:method].nil? && !self.new?)
        o << "<input type='hidden' name='_method' value='#{opts[:method]}' />\n" unless opts[:method].nil?
        o << "<input type='hidden' name='_destination' value='#{opts[:destination]}' />\n" unless opts[:destination].nil?
        o << "<input type='hidden' name='_submit_text' value='#{opts[:submit_text]}' />\n" unless opts[:submit_text].nil?
        o << "<input type='hidden' name='_no_wrap' value='#{opts[:no_wrap]}' />\n" unless opts[:no_wrap].nil?
        cols.each do |c|
          o << "<input type='hidden' name='fields[]' value='#{c}' />\n"
        end
        o << "<input type='submit' name='save' value='#{opts[:submit_text] || 'SAVE'}' />\n"
        o << "</form>\n"
        o
      end
      def backend_delete_form(url, opts={}); backend_form(url, [], {:submit_text=>'X', :method=>'DELETE'}.update(opts)){}; end
      def backend_clone_form(url, opts={})
        backend_form(url, [], {:submit_text=>'CLONE', :method=>'POST'}.update(opts)) do |out|
          out << "<input type='hidden' name='clone_id' value='#{self.id}' />\n"
        end
      end
      # Silly but usable form prototype
      # Not really meant to be used in a real case
      # It uses a textarea for everything
      # Override it
      # Or even better, use Sequel-Crushyform plugin instead
      def backend_fields(cols)
        o = ''
        cols.each do |c|
          identifier = "#{id}-#{self.class}-#{c}"
          o << "<label for='#{identifier}'>#{c.to_s.capitalize}</label><br />\n"
          o << "<textarea id='#{identifier}' name='model[#{c}]'>#{self[c]}</textarea><br />\n"
        end
        o
      end
    	def backend_form_title; self.new? ? "New #{model.human_name}" : "Edit #{self.to_label}"; end
    	def backend_show; 'OK'; end
	
    	def default_backend_columns; model.schema.keys; end
    	def cloning_backend_columns; default_backend_columns.reject{|c| model.schema[c][:type]==:attachment}; end

    end
  end
end

