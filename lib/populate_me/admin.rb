require 'populate_me/api'

class PopulateMe::Admin < Sinatra::Base
  # Mount assets on /__assets__
  use Rack::Static, :urls=>['/__assets__'], :root=>File.expand_path('../admin',__FILE__)
  # Mount the API on /api
  use Rack::Builder do 
    map('/api'){ run PopulateMe::API }
  end
  # Reset :app_file so that it will be correct when class is inherited
  set :app_file, nil
  # Load API helpers
  helpers PopulateMe::API::Helpers
  helpers do
    def menu_href(key, value)
      return value if value.is_a?(String)
      if value.is_a?(Array)
        return "#{request.script_name}/menu/#{params[:splat].join('/')}#{'/' unless params[:splat].empty?}#{escape(key)}" 
      end
      raise "The admin menu is not correctly formated"
    end
  end
  # Make all templates in admin/views accessible with their basename
  Dir["#{File.expand_path('../admin/views',__FILE__)}/*.erb"].each do |f|
    template File.basename(f,'.erb').to_sym do
      File.read(f)
    end
  end

  before do
    @meta_title = "Populate Me"
  end
  get '/menu/?*' do
    @level_menu = settings.menu
    params[:splat].each do |l|
      next if blank?(l)
      @level_menu = @level_menu.assoc(unescape(l))[1]
    end
    @level_menu.map! do |l|
      {
        title: l[0],
        href: menu_href(l[0],l[1])
      }
    end
    erb :menu, layout: !request.xhr?
  end
end

