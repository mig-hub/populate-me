module Rack
  module Populate
    def self.included(klass)
      klass.extend ClassMethods
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
      @r.env['erb.location'] = DIR+'/../views/'
      erb :index
    end
  end
end

