require 'populate_me/document'


module PopulateMe

  class MissingDocumentError < StandardError; end

  module Mongo
    
    include PopulateMe::Document

  end

end