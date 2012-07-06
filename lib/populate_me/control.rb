require 'rack/golem'
require 'json'

module PopulateMe
  module Control
    F = ::File
    DIR = F.expand_path(F.dirname(__FILE__)+'/control')
    BEFORE = proc{
    }

    def self.included(klass)
      klass.class_eval do
        include ::Rack::Golem
        extend ClassMethods
      end
      klass.before(&BEFORE)
    end

    module ClassMethods
      def new(*)
        ::Rack::Static.new(::Rack::MethodOverride.new(super), :urls => ["/_public"], :root => DIR)
      end 
      def config
        @config ||= {
          :client_name => 'Client Name',
          :website_url => 'www.domain.com',
          :page_title => 'Populate Me',
          :path => '/admin',
          :logout_path => '/admin/logout', # sometimes higher in stack
          :menu => [['Home', '/admin']],
        }
      end
    end

    def index(class_name=nil, id=nil)
      if class_name.nil?
        @r.env['erb.location'] = DIR+'/views/'
        erb :populate_me_layout
      else
        http_method = @r.request_method.downcase
        if ['post','put','delete'].include?(http_method)
          @model_class_name, @id = class_name, id
          build_model_vars
          return if @res.status==404
          @res['Content-Type'] = 'text/json'
          __send__(http_method)
        else
          send_404
          '' # Trick for the moment but it needs a throw for 404
        end
      end
    end    

    def menu(*levels)
      level_menu = config[:menu]
      levels.each do |l|
        level_menu = level_menu.assoc(l)[1]
      end
      items = level_menu.map do |i|
        {
          'title'=>i[0].gsub(/-/, ' '),
          'href'=> i[1].kind_of?(String) ? i[1] : "#{config[:path]}/menu/#{levels.join('/')}/#{i[0]}"
        }
      end
      page_title = levels.empty? ? config[:page_title] : levels.join(' / ').gsub(/-/, ' ')
      
      @res['Content-Type'] = 'text/json'
      JSON.generate({
        'action'=>'menu',
        'page_title'=>page_title,
        'items'=>items
      })
    end

    def list(class_name)
      @model_class_name = class_name
      resolve_model_class
      items = @model_class.find(@r['filter']||{}).map {|m| m.to_nutshell }
      
      @res['Content-Type'] = 'text/json'
      JSON.generate({
        'action'=> 'list',
        'page_title'=> @model_class.human_plural_name,
        'class_name'=> class_name,
        'sortable'=> @model_class.sortable_on_that_page?(@r),
        'command_plus'=> !@model_class.populate_config[:no_plus],
        'command_search'=> !@model_class.populate_config[:no_search],
        'items'=> items,
      })
    end

    def form(class_name=nil, id=nil)
      @model_class_name, @id = class_name, id
      build_model_vars
      return if @res.status==404
      @model_instance ||= @model_class.backend_post
      @model_instance.backend_put @r['model']
      form = @model_instance.backend_form(@r.path.sub(/\/form/, ''), @r['fields'], :destination => @r['_destination'], :submit_text => @r['_submit_text'])
      
      @res['Content-Type'] = 'text/json'
      JSON.generate({
        'action'=> 'form',
        'page_title'=> @model_instance.backend_form_title,
        'form'=>form
      })
    end
    
    private

    def config
      @config ||= self.class.config.update({
        :path => @r.script_name, 
        :logout_path => "#{@r.script_name}/logout"
      }).dup
    end
    
    def resolve_model_class
      if @model_class_name.nil?
        raise("No model class name provided")
      end
      unless ::Object.const_defined?(@model_class_name)
        raise("#{@model_class_name} is not constant")
      end
      @model_class = Kernel.const_get(@model_class_name)
      unless @model_class.kind_of?(PopulateMe::Mongo::BackendApiPlug::ClassMethods)
        raise("Requested constant #{@model_class_name} is not a model class")
      end
    end
    
    def build_model_vars
      resolve_model_class
      @model_instance = @model_class.backend_get(@id) unless @id.nil?
      @clone_instance = @model_class.backend_get(@r['clone_id']) unless @r['clone_id'].nil?
      unless @clone_instance.nil?
        @r['fields'] ||= @clone_instance.cloning_backend_columns
        @r['model'] = @clone_instance.backend_values.reject{|k,v| !@r['fields'].include?(k.to_s)}
      end
      @r['model'] ||= {}
      send_404 if @model_instance.nil?&&!@id.nil?
    end
    
    def post
      return put unless @id.nil?
      @model_instance = @model_class.backend_post(@r['model'])
      save_and_respond
    end
    
    def put
      if @id.nil? && @r[@model_class_name]
        @model_class.sort(@r[@model_class_name])
        JSON.generate({'ids'=>@r[@model_class_name]})
      else
        @model_instance.backend_put(@r['model'])
        save_and_respond
      end
    end
    
    def delete
      @model_instance.backend_delete
      @r['_destination'].nil? ? @res.status=204 : @res.redirect(::Rack::Utils::unescape(@r['_destination'])) # 204 No Content
    end
    
    def save_and_respond
      if @model_instance.backend_save?
        if @r['_destination'].nil?
          @res.status=201 # Created
          JSON.generate({
            'action'=> 'save',
            'message'=> 'ok'
          })
        else
          @res.redirect(::Rack::Utils::unescape(@r['_destination']))
        end
      else
        form = @model_instance.backend_form(@r.path, @r['fields']||@r['model'].keys, :destination => @r['_destination'], :submit_text => @r['_submit_text'])
        # Bad Request 400 does not give content anymore in safari/lion
        # So I put 200 back until I find a better code
        JSON.generate({
          'action'=> 'validation',
          'form'=>form
        })
      end
    end
    
    def send_404
      @res.status=404 # Not Found
      @res.headers['X-Cascade']='pass'
      @res.write 'Not Found'
    end

  end
end

