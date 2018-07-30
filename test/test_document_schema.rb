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

  describe 'Polymorphism' do

    class PolyBox < PopulateMe::Document
      field :first_name
      field :last_name
      field :middle_name, only_for: ['Middle', 'Long name']
      field :nick_name, only_for: 'Funny'
      field :third_name, only_for: 'Long name'
    end

    class NotPoly < PopulateMe::Document
      field :name
      relationship :images
    end

    class JustPoly < PopulateMe::Document
      polymorphic
    end

    class PolyCustom < PopulateMe::Document
      polymorphic type: :text, custom_option: 'Custom'
    end

    class PolyApplicable < PopulateMe::Document
      field :name_1, only_for: 'Shape 1'
      field :name_2, only_for: 'Shape 2'
      field :position
    end

    class PolyLabel < PopulateMe::Document
      polymorphic
      field :name
    end

    class PolyRelationship < PopulateMe::Document
      field :name
      field :short_description, only_for: 'Chapter'
      relationship :images, only_for: 'Slider'
      relationship :paragraphs, only_for: 'Chapter'
    end

    class PolyGroup < PopulateMe::Document
      only_for 'Slider' do
        field :name
        relationship :images
      end
      field :no_only_for
      only_for ['Try','This'] do
        field :crazy
      end
      field :position
    end

    it 'Creates a field for polymorphic type if it does not exist yet' do
      assert_equal :polymorphic_type, PolyBox.fields[:polymorphic_type][:type]
      assert_equal :polymorphic_type, JustPoly.fields[:polymorphic_type][:type]
      assert_equal :polymorphic_type, PolyRelationship.fields[:polymorphic_type][:type]
    end

    it 'Does not create polymorphic type field if not required' do
      assert_nil NotPoly.fields[:polymorphic_type]
    end

    it 'Gathers all polymorphic type unique values' do
      assert_equal ['Middle', 'Long name', 'Funny'], PolyBox.fields[:polymorphic_type][:values]
      assert_equal [], JustPoly.fields[:polymorphic_type][:values]
      assert_equal ['Chapter', 'Slider'], PolyRelationship.fields[:polymorphic_type][:values]
    end

    it 'Adds or update field options for polymorphic type passed as arguments' do
      assert_equal :text, PolyCustom.fields[:polymorphic_type][:type]
      assert_equal 'Custom', PolyCustom.fields[:polymorphic_type][:custom_option]
    end

    it 'Forces only_for field option to be an Array if String' do
      assert_nil PolyBox.fields[:first_name][:only_for]
      assert_equal ['Middle', 'Long name'], PolyBox.fields[:middle_name][:only_for]
      assert_equal ['Funny'], PolyBox.fields[:nick_name][:only_for]
      assert_equal ['Slider'], PolyRelationship.relationships[:images][:only_for]
    end

    it 'Has a polymorphic? predicate' do
      assert PolyBox.polymorphic?
      refute NotPoly.polymorphic?
    end

    it 'Knows when a field is applicable to a polymorphic_type' do
      assert NotPoly.field_applicable?(:name, nil) # Not polymorphic
      assert NotPoly.field_applicable?(:name, 'Fake') # Not polymorphic
      refute NotPoly.field_applicable?(:non_existing_field, nil) # Not polymorphic
      assert PolyApplicable.field_applicable?(:polymorphic_type, 'Shape 1') # no only_for
      assert PolyApplicable.field_applicable?(:position, 'Shape 1') # no only_for
      refute PolyApplicable.field_applicable?(:name_2, 'Shape 1') # not included
      assert PolyApplicable.field_applicable?(:name_2, nil) # no type set yet

      assert NotPoly.new.field_applicable?(:name) # Not polymorphic
      refute NotPoly.new.field_applicable?(:non_existing_field) # Not polymorphic
      assert PolyApplicable.new(polymorphic_type: 'Shape 2').field_applicable?(:name_2)
      refute PolyApplicable.new(polymorphic_type: 'Shape 2').field_applicable?(:name_1)
      assert PolyApplicable.new.field_applicable?(:name_2) # No type set yet
      assert PolyApplicable.new.field_applicable?(:name_1) # No type set yes
    end

    it 'Knows when a relationship is applicable to a polymorphic_type' do
      assert PolyRelationship.relationship_applicable?(:images, 'Slider')
      refute PolyRelationship.relationship_applicable?(:images, 'Chapter')
      assert PolyRelationship.new(polymorphic_type: 'Slider').relationship_applicable?(:images)
      refute PolyRelationship.new(polymorphic_type: 'Chapter').relationship_applicable?(:images)
    end

    it 'Ignores polymorphic_type when picking the default label_field' do
      assert_equal :name, PolyLabel.label_field
    end

    it 'Uses groups to define only_for option for all included fields and relationships' do
      assert_equal :polymorphic_type, PolyGroup.fields[:polymorphic_type][:type]
      assert_equal ['Slider', 'Try', 'This'], PolyGroup.fields[:polymorphic_type][:values]
      assert_equal ['Slider'], PolyGroup.fields[:name][:only_for]
      assert_equal ['Slider'], PolyGroup.relationships[:images][:only_for]
      assert_equal ['Try','This'], PolyGroup.fields[:crazy][:only_for]
    end

    it 'Group only_for option does not leak on special fields' do
      refute PolyGroup.fields[:id].key?(:only_for)
      refute PolyGroup.fields[:polymorphic_type].key?(:only_for)
    end

    it 'Group only_for option does not leak outside of their scope' do
      refute PolyGroup.fields[:no_only_for].key?(:only_for)
      refute PolyGroup.fields[:position].key?(:only_for)
    end

  end

end

