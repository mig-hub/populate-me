require 'populate_me/api'

class PopulateMe::Admin < Sinatra::Base
  use Rack::Static, :urls=>['/__assets__'], :root=>File.expand_path('../admin',__FILE__)
  use Rack::Builder do 
    map('/api'){ run PopulateMe::API }
  end
  set :app_file, nil
  helpers PopulateMe::API::Helpers
end

