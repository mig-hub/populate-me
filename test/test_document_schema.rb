require 'helper'
require 'populate_me/document'

describe PopulateMe::Document, 'Schema' do

  parallelize_me!

  describe "Relationships" do

    class Relative < PopulateMe::Document
      relationship :siblings
      relationship :home_remedies
      relationship :friends, label: 'Budies', class_name: 'Budy', foreign_key: :budy_id, dependent: false
    end

    class Relative::Sibling < PopulateMe::Document
      field :size
      field :relative_id, type: :parent
    end

    before do
      Relative.documents = []
      Relative::Sibling.documents = []
    end

    it "Defaults class name" do
      assert_equal "Relative::Sibling", Relative.relationships[:siblings][:class_name]
      assert_equal "Relative::HomeRemedy", Relative.relationships[:home_remedies][:class_name]
    end

    it "Defaults label" do
      assert_equal "Siblings", Relative.relationships[:siblings][:label]
      assert_equal "Home remedies", Relative.relationships[:home_remedies][:label]
    end

    it "Defaults foreign key" do
      assert_equal :relative_id, Relative.relationships[:siblings][:foreign_key]
      assert_equal :relative_id, Relative.relationships[:home_remedies][:foreign_key]
    end

    it "Defaults :dependent to true" do
      assert Relative.relationships[:siblings][:dependent]
    end

    it "Has everything editable" do
      assert_equal "Budies", Relative.relationships[:friends][:label]
      assert_equal "Budy", Relative.relationships[:friends][:class_name]
      assert_equal :budy_id, Relative.relationships[:friends][:foreign_key]
      refute Relative.relationships[:friends][:dependent]
    end

    it "Creates a getter for cached items" do
      relative = Relative.new(id: 10)
      relative.save
      Relative::Sibling.new(relative_id: 10, size: 'S').save
      Relative::Sibling.new(relative_id: 10, size: 'M').save
      Relative::Sibling.new(relative_id: 10, size: 'L').save
      assert relative.respond_to? :siblings
      assert_nil relative.instance_variable_get('@cached_siblings')
      siblings = relative.siblings
      assert_equal 3, siblings.size
      assert_equal siblings, relative.instance_variable_get('@cached_siblings')
    end

    it "Creates a getter for cached first item" do
      relative = Relative.new(id: 10)
      relative.save
      Relative::Sibling.new(relative_id: 10, size: 'S').save
      Relative::Sibling.new(relative_id: 10, size: 'M').save
      Relative::Sibling.new(relative_id: 10, size: 'L').save
      assert relative.respond_to? :siblings_first
      assert_nil relative.instance_variable_get('@cached_siblings_first')
      sibling = relative.siblings_first
      assert_equal 'S', sibling.size
      assert_equal sibling, relative.instance_variable_get('@cached_siblings_first')
    end

  end

end

