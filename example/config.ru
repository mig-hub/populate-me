$:.unshift File.expand_path('../../lib', __FILE__)
require 'populate_me'

# Model ##########

class User
  include PopulateMe::Utils
  def api_get(id)
    {'yo'=>'man'}
  end
end


# Rackup ##########

map '/api' do
  run PopulateMe::API
end

