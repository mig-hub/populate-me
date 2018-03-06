require 'helper'
require 'populate_me/document'

class Stuborn < PopulateMe::Document
  attr_accessor :age
  field :position
  field :reversed, direction: :desc
end

describe PopulateMe::Document, 'Persistence' do

  parallelize_me!

  let(:subject_class) { Stuborn }
  subject { subject_class.new }

  describe '::is_unique' do

    before do
      Stuborn.documents = []
    end

    # def doc_doesnt_exist
    #   subject_class.stub(:admin_get, nil) do
    #     yield
    #   end
    # end
    # def doc_exists
    #   subject_class.stub(:admin_get, subject) do
    #     yield
    #   end
    # end

    describe 'The document does not exist yet' do
      it 'Saves an entry with the ID `unique` by default' do
        Stuborn.is_unique
        assert_equal 1, Stuborn.documents.count
        assert_equal 'unique', Stuborn.documents[0]['id']
      end
      it 'Saves an entry with a provided ID' do
        Stuborn.is_unique('provided_id')
        assert_equal 1, Stuborn.documents.count
        assert_equal 'provided_id', Stuborn.documents[0]['id']
      end
    end
    describe 'The document already exist' do
      it 'Does not create a new document and preserve the current one' do
        doc = Stuborn.new({'id'=>'unique', 'age'=>4})
        doc.save
        Stuborn.is_unique
        assert_equal 1, Stuborn.documents.count
        assert_equal doc.to_h, Stuborn.documents[0]
      end
    end
  end

  describe '::set_indexes' do

    before do
      Stuborn.documents = []
      Stuborn.new('id' => 'a').save
      Stuborn.new('id' => 'b').save
      Stuborn.new('id' => 'c').save
    end

    it 'Sets the indexes on the provided field' do
      Stuborn.set_indexes(:position,['b','a','c'])
      assert_equal 1, Stuborn.admin_get('a').position
      assert_equal 0, Stuborn.admin_get('b').position
      assert_equal 2, Stuborn.admin_get('c').position
    end

    it 'Sets the indexes taking direction into account' do
      Stuborn.set_indexes(:reversed,['b','a','c'])
      assert_equal 1, Stuborn.admin_get('a').reversed
      assert_equal 2, Stuborn.admin_get('b').reversed
      assert_equal 0, Stuborn.admin_get('c').reversed
    end

  end

end

