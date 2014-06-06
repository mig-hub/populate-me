require 'populate_me/api'

class PopulateMe::Admin < Sinatra::Base
  use Rack::Static, :urls=>['/__assets__'], :root=>File.expand_path('../admin',__FILE__)
  set :api_path, '/api'


  helpers PopulateMe::API::Helpers
end

