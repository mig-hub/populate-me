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

  describe '::to_select_options' do

    class Selectoptionable < PopulateMe::Document
      field :name
      field :slug
      label :slug
    end

    before do
      Selectoptionable.documents = []
      Selectoptionable.new(id: '1', name: 'Joe', slug: 'joe').save
      Selectoptionable.new(id: '2', name: 'William', slug: 'william').save
      Selectoptionable.new(id: '3', name: 'Jack', slug: 'jack').save
      Selectoptionable.new(id: '4', name: 'Averell', slug: 'averell').save
    end

    after do
      Selectoptionable.documents = []
    end

    it 'Formats all items for a select_options' do
      output_proc = Selectoptionable.to_select_options
      assert output_proc.is_a?(Proc)
      output = output_proc.call
      assert_equal 4, output.size
      assert output.all?{|o| o.is_a?(Array) and o.size==2}
      assert_equal '1', output.find{|o|o[0]=='joe'}[1]
    end

    it 'Puts items in alphabetical order of their label' do
      output= Selectoptionable.to_select_options.call
      assert_equal ['averell', '4'], output[0]
    end

    it 'Has an option for prepending empty choice' do
      output= Selectoptionable.to_select_options(allow_empty: true).call
      assert_equal ['?', ''], output[0]
      assert_equal ['averell', '4'], output[1]
    end

  end

end

