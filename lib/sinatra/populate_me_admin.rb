require 'populate_me/api'

module Sinatra
  module PopulateMeAdmin

    def self.registered(app)
      app.helpers PopulateMe::API::Helpers
      app.set :api_path, '/api'
      app.use Rack::Static, :urls=>['/__populateme__'], :root=>File.expand_path('..',__FILE__)
    end

  end
end

