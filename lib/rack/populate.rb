require 'rack/golem'
require 'backend_api'
require 'json'

module Rack
  module Populate
    F = ::File
    DIR = F.expand_path(F.dirname(__FILE__)+'/populate')
    BEFORE = proc{
      @r.env['erb.location'] = DIR+'/views/' if ['index', 'menu', 'list', 'form'].include?(@action)
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
          :menu => [['Home', '/admin']],
        }
      end
    end

    def index
      menu
    end    

    def menu(*levels)
      @levels = levels
      @items = config[:menu]
      levels.each do |l|
        @items = @items.assoc(l)[1]
      end
      @content = :menu
      erb :layout
    end

    def list(m)
      model = Kernel.const_get(m)
      @content = :list
      erb :layout
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
      @config ||= self.class.config.update(:path=>@r.script_name).dup
    end

  end
end

