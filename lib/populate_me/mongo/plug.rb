# encoding: utf-8

require 'populate_me/mongo/mutation'
require 'populate_me/mongo/stash'
require 'populate_me/mongo/crushyform'
require 'populate_me/mongo/backend_api_plug'

module PopulateMe
  module Mongo
    module Plug
  
      # This module is the one that plugs the model to the CMS
  
      def self.included(base)
        base.class_eval do
          include PopulateMe::Mongo::Mutation
          include PopulateMe::Mongo::Stash if (base.const_defined?(:WITH_STASH) && base::WITH_STASH)
          include PopulateMe::Mongo::BackendApiPlug
          include PopulateMe::Mongo::Crushyform
          include InstanceMethods
        end
        base.extend(ClassMethods)
        base.populate_config = {:nut_tree_class=>'sortable-grid'}
      end

      module ClassMethods
    
        attr_accessor :populate_config
    
        #     def list_view(r)
        #   @list_options = {:request=>r, :destination=>r.fullpath, :path=>r.script_name, :filter=>r['filter'] }
        #   @list_options.store(:sortable,sortable_on_that_page?)
        #   out = list_view_header
        #   out << many_to_many_picker unless populate_config[:minilist_class].nil?
        #   out << "<ul class='nut-tree #{'sortable' if @list_options[:sortable]} #{populate_config[:nut_tree_class]}' id='#{self.name}' rel='#{@list_options[:path]}/#{self.name}'>"
        #   self.find(@list_options[:filter]||{}).each {|m| out << m.to_nutshell }
        #   out << "</ul>"
        # end
    
        def sortable_on_that_page?(r)
          @schema.key?('position') && (@schema['position'][:scope].nil? || (r['filter']||{}).key?(@schema['position'][:scope]))
        end
    
        # def minilist_view
        #   o = "<ul class='minilist'>\n"
        #   self.collection.find.each_mutant do |m|
        #     thumb = m.respond_to?(:to_populate_thumb) ? m.to_populate_thumb('stash_thumb_gif') : m.placeholder_thumb('stash_thumb_gif')
        #     o << "<li title='#{m.to_label}' id='mini-#{m.id}'>#{thumb}<div>#{m.to_label}</div></li>\n"
        #   end
        #   o << "</ul>\n"
        # end
    
        private
    
        def image_slot(name='image',opts={})
          super(name,opts)
          # First image slot is considered the best populate thumb by default
          unless instance_methods.include?(:to_populate_thumb)
            define_method :to_populate_thumb do |style|
              generic_thumb(name, style)
            end
          end
        end

      end
  
      module InstanceMethods

        def after_stash(col)
          convert(col, "-resize '100x75^' -gravity center -extent 100x75", 'stash_thumb_gif')
        end

        def generic_thumb(img , size='stash_thumb_gif', obj=self)
          return placeholder_thumb(size) if obj.nil?
          current = obj.doc[img]
          if !current.nil? && !current[size].nil?
            "/gridfs/#{current[size]}"
          else
            placeholder_thumb(size)
          end
        end
  
        def placeholder_thumb(size)
          "/_public/img/placeholder.#{size.gsub(/^(.*)_([a-zA-Z]+)$/, '\1.\2')}"
        end
  
        def to_nutshell
          {
            'class_name'=>model.name,
            'id'=>@doc['_id'].to_s,
            'foreign_key_name'=>model.foreign_key_name,
            'title'=>self.to_label,
            'thumb'=>self.respond_to?(:to_populate_thumb) ? self.to_populate_thumb('stash_thumb_gif') : nil,
            'children'=>nutshell_children,
          }
        end
  
        def in_nutshell
          o = model.list_options
          out = "<div class='in-nutshell'>\n"
          out << self.to_populate_thumb('nutshell_jpg') if self.respond_to?(:to_populate_thumb)
          cols = model.populate_config[:quick_update_fields] || nutshell_backend_columns.select{|col| 
            [:boolean,:select].include?(model.schema[col][:type]) && !model.schema[col][:multiple] && !model.schema[col][:no_quick_update]
          }
          cols.each do |c|
            column_label = c.to_s.sub(/^id_/, '').tr('_', ' ').capitalize
            out << "<div class='quick-update'><form><span class='column-title'>#{column_label}:</span> #{self.crushyinput(c)}</form></div>\n"
          end
          out << "</div>\n"
        end

        def nutshell_backend_associations
          model.relationships
        end
  
        def nutshell_children
          nutshell_backend_associations.inject([]) do |arr, (k, opts)|
            unless opts[:hidden]
              klass = Kernel.const_get(k)
              arr << {
                'children_class_name'=>k,
                'title'=>opts[:link_text] || "#{klass.human_name}(s)",
                'count'=>self.children_count(klass),
              }
            end
          end
        end
        
      end

    end
  end
end

