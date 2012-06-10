require 'rack/golem'
require 'backend_api'
require 'json'

module Rack
  module Populate
    F = ::File
    DIR = F.expand_path(F.dirname(__FILE__)+'/populate')
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
        ::Rack::Static.new(BackendAPI.new(super), :urls => ["/_public"], :root => DIR)
      end 
      def config
        @config ||= {
          :client_name => 'Client Name',
          :website_url => 'www.domain.com',
          :path => '/admin',
          :logout_path => '/admin/logout', # sometimes higher in stack
          #:menu => [['Home', '/admin']],
          :menu => [['Home', [
            ['One', [
              ['Fist', '/'],
              ['Fucking', '/'],
            ]],
            ['Two', '/admin/list/Project'],
            ['Three', '/'],
            ['Four', '/']
          ]]],
        }
      end
    end

    def index
      @r.env['erb.location'] = DIR+'/views/'
      erb :layout
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
      
      @res['Content-Type'] = 'text/json'
      JSON.generate({
        'action'=>'menu',
        'page_title'=>levels.join(' / ').gsub(/-/, ' '),
        'items'=>items
      })
    end

    def list(class_name)
      model = Kernel.const_get(class_name)
      items = model.find(@r['filter']||{}).map {|m| m.to_nutshell }
      
      @res['Content-Type'] = 'text/json'
      JSON.generate({
        'action'=> 'list',
        'page_title'=> model.human_plural_name,
        'class_name'=> class_name,
        'sortable'=> model.sortable_on_that_page?(@r),
        'command_plus'=> !model.populate_config[:no_plus],
        'command_search'=> !model.populate_config[:no_search],
        'items'=> items,
      })
    end

    def form(*args)
      new_env = @r.env.dup.update({'PATH_INFO'=>@r.env['PATH_INFO'].sub('form/','')})
      status, header, res = BackendAPI.new.call(new_env)
      @res.status = status
      @res.header.replace(header)
      @form = res.body.inject(''){|r,s| r+s }
      @content = :form
      erb :layout
    end
    
    private

    def config
      @config ||= self.class.config.update({
        :path => @r.script_name, 
        :logout_path => "#{@r.script_name}/logout"
      }).dup
    end

  end
end

