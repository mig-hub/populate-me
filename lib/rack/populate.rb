require 'rack/golem'
require 'json'

module Rack
  module Populate
    F = ::File
    DIR = F.expand_path(F.dirname(__FILE__)+'/populate')
    def self.included(klass)
      klass.class_eval do
        include ::Rack::Golem
        extend ClassMethods
      end
    end

    module ClassMethods
      def new(*)
        ::Rack::Static.new(super, :urls => ["/_public"], :root => DIR)
      end 
      def config
        @config ||= {
          :client_name => 'Client Name',
          :website_url => 'www.domain.com',
          :path => '/admin',
          :logout_path => '/admin/logout', # sometimes higher in stack
          :menu => ['Home', '/'],
        }
      end
    end

    def config
      @config ||= self.class.config.update(:path=>@r.script_name).dup
    end
    def index
      @r.env['erb.location'] = DIR+'/views/'
      erb :index
    end
    def menu
      @res['Content-Type'] = 'application/json'
      JSON.generate(config[:menu])
    end
  end
end

