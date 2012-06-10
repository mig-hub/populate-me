require 'mongo_mutation'
require 'mongo_crushyform'
require 'mongo_stash'
require 'backend_api_adapter'

module MongoPopulate
  
	def self.included(base)
	  base.extend(BackendApiAdapter::ClassMethods)
		base.extend(MongoCrushyform::ClassMethods)
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
    #     thumb = m.respond_to?(:to_populate_thumb) ? m.to_populate_thumb('stash_thumb.gif') : m.placeholder_thumb('stash_thumb.gif')
    #     o << "<li title='#{m.to_label}' id='mini-#{m.id}'>#{thumb}<div>#{m.to_label}</div></li>\n"
    #   end
    #   o << "</ul>\n"
    # end
    
    private
    
    def image_slot(name='image',opts={})
		  super(name,opts)
			# First image slot is considered the best populate thumb
			unless instance_methods.include?(:to_populate_thumb)
			  define_method :to_populate_thumb do |style|
				  generic_thumb(name, style)
				end
			end
		end

	end

  include BackendApiAdapter::InstanceMethods
	include MongoCrushyform::InstanceMethods

	def after_stash(col)
	  convert(col, "-resize '100x75^' -gravity center -extent 100x75", 'stash_thumb.gif')
	end

  def generic_thumb(img , size='stash_thumb.gif', obj=self)
    return placeholder_thumb(size) if obj.nil?
	  current = obj.doc[img]
		if !current.nil? && !current[size].nil?
		  "<img src='/gridfs/#{current[size]}' onerror=\"this.style.display='none'\" />\n"
		else
		  placeholder_thumb(size)
		end
	end
	
	def to_nutshell
	  @doc
  end
	
	def in_nutshell
    o = model.list_options
		out = "<div class='in-nutshell'>\n"
		out << self.to_populate_thumb('nutshell.jpg') if self.respond_to?(:to_populate_thumb)
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
		o = model.list_options
		out = ""
		nutshell_backend_associations.each do |k, opts|
		  next if opts[:hidden]
		  k = Kernel.const_get(k)
			link = "#{o[:path]}/list/#{k}?filter[#{model.foreign_key_name}]=#{self.id}"
			text = opts[:link_text] || "#{k.human_name}(s)"
			out << "<a href='#{link}' class='push-stack sublist-link nutshell-child'>#{text} #{self.children_count(k)}</a>\n"
		end
		out
	end
    
  def default_backend_columns; model.schema.keys; end
	def cloning_backend_columns; default_backend_columns.reject{|c| model.schema[c][:type]==:attachment}; end

end

