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

  end

end

