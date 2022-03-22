require 'helper'
require 'populate_me/document'
require 'populate_me/attachment'

class Outcasted < PopulateMe::Document
  set :default_attachment_class, PopulateMe::Attachment

  field :name
  field :category, autocomplete: ['Fish', 'Cat', 'Bunny']
  field :size, type: :select, select_options: [
    {description: 'small', value: 's'},
    {description: 'medium', value: 'm'},
    {description: 'large', value: 'l'}
  ]
  field :availability, type: :select, select_options: [
    {description: 'Available', value: 'yes', preview_uri: 'http://www.example.org/yes.jpg' },
    {description: 'On offer', value: 'almost', preview_uri: 'http://www.example.org/almost.jpg' },
    {description: 'Sold', value: 'no', preview_uri: 'http://www.example.org/no.jpg' }
  ]
  field :tags, type: :select, select_options: ['art','sport','science'], multiple: true
  field :related_properties, type: :select, select_options: ['prop1','prop2','prop3'], multiple: true
  field :pdf, type: :attachment
  field :image, type: :attachment
  field :authors, type: :list
  field :weirdo, type: :strange
  field :price, type: :price

  batch_on_field :image

  def get_category_autocomplete_list
    ['Horse', 'Bear']
  end

  def get_size_options
    [
      [:small, :s],
      [:medium, :m],
      [:large, :l]
    ]
  end

end

class Outcasted::Author < PopulateMe::Document
  field :name
end

class OutcastedNoBatchField < PopulateMe::Document
  set :default_attachment_class, PopulateMe::Attachment
  field :image, type: :attachment
end

describe PopulateMe::Document, 'Outcasting' do

  parallelize_me!

  describe '#outcast' do

    it 'Keeps the original info unchanged' do
      original = Outcasted.fields[:name]
      output = Outcasted.new.outcast(:name, original, {input_name_prefix: 'data'})
      refute original.equal?(output)
    end

    it 'Adds input_name_prefix to input_name' do
      original = Outcasted.fields[:name]
      output = Outcasted.new.outcast(:name, original, {input_name_prefix: 'data'})
      assert_equal 'data[name]', output[:input_name]
    end

    it 'Sets input_value to the field value' do
      original = Outcasted.fields[:name]
      outcasted = Outcasted.new
      outcasted.name = 'Thomas'
      output = outcasted.outcast(:name, original, {input_name_prefix: 'data'})
      assert_equal 'Thomas', output[:input_value]
    end

  end

  describe '#outcast_string' do

    it 'Generates the autocomplete options when needed' do
      original = Outcasted.fields[:category]
      output = Outcasted.new.outcast(:category, original, {input_name_prefix: 'data'})
      assert_equal ['Fish', 'Cat', 'Bunny'], output[:autocomplete]
      refute original.equal?(output)

      original = Outcasted.fields[:name]
      output = Outcasted.new.outcast(:name, original, {input_name_prefix: 'data'})
      refute output.key?(:autocomplete)
    end

    it 'Generates the autocomplete options from a proc' do
      original = Outcasted.fields[:category].dup
      original[:autocomplete] = proc{ ['Dog', 'Snake'] }
      output = Outcasted.new.outcast(:category, original, {input_name_prefix: 'data'})
      assert_equal ['Dog', 'Snake'], output[:autocomplete]
      assert original[:autocomplete].is_a?(Proc)
    end

    it 'Generates the autocomplete options from a method name' do
      original = Outcasted.fields[:category].dup
      original[:autocomplete] = :get_category_autocomplete_list
      output = Outcasted.new.outcast(:category, original, {input_name_prefix: 'data'})
      assert_equal ['Horse', 'Bear'], output[:autocomplete]
      assert original[:autocomplete].is_a?(Symbol)
    end
  end

  describe '#outcast_list' do

    it 'Has no value and an empty list of items when list is empty' do
      original = Outcasted.fields[:authors]
      output = Outcasted.new.outcast(:authors, original, {input_name_prefix: 'data'})
      assert_nil output[:input_value]
      assert_equal [], output[:items]
    end

    it 'Nests the items in the list with their own nested prefix' do
      original = Outcasted.fields[:authors]
      outcasted = Outcasted.new
      outcasted.authors.push(Outcasted::Author.new(name: 'Bob'))
      outcasted.authors.push(Outcasted::Author.new(name: 'Mould'))
      output = outcasted.outcast(:authors, original, {input_name_prefix: 'data'})
      assert_nil output[:input_value]
      assert_equal 2, output[:items].size
      first_item = output[:items][0][:fields]
      assert_equal 'data[authors][][name]', first_item[1][:input_name]
      assert_equal 'Bob', first_item[1][:input_value]
    end

  end

  describe '#outcast_select' do

    def formated_options? original, output
      assert_equal [ {description: 'small', value: 's'}, {description: 'medium', value: 'm'}, {description: 'large', value: 'l'} ], output[:select_options]
      refute original[:select_options].equal?(output[:select_options])
      assert output[:select_options].all?{|o|!o[:selected]}
    end

    it 'Leaves the options as they are when they are already formated' do
      original = Outcasted.fields[:size]
      output = Outcasted.new.outcast(:size, original, {input_name_prefix: 'data'})
      formated_options?(original, output)
    end

    it 'Can have more fields when they are already formated' do
      # Mainly for adding a preview_uri but also future tweaks
      original = Outcasted.fields[:availability]
      output = Outcasted.new.outcast(:availability, original, {input_name_prefix: 'data'})
      assert(output[:select_options].all?{|o| o.key?(:preview_uri)})
      last = output[:select_options].last
      assert_equal 'Sold', last[:description]
      assert_equal 'no', last[:value]
      assert_equal 'http://www.example.org/no.jpg', last[:preview_uri]
    end

    it 'Formats the options when it is a 2 strings array' do
      original = Outcasted.fields[:size].dup
      original[:select_options] = [
        [:small, :s],
        [:medium, :m],
        [:large, :l]
      ]
      output = Outcasted.new.outcast(:size, original, {input_name_prefix: 'data'})
      formated_options?(original, output)
    end

    it 'Formats the options when they come from a proc' do
      original = Outcasted.fields[:size].dup
      original[:select_options] = proc{[
        [:small, :s],
        [:medium, :m],
        [:large, :l]
      ]}
      output = Outcasted.new.outcast(:size, original, {input_name_prefix: 'data'})
      formated_options?(original, output)
    end

    it 'Formats the options when they come from a symbol' do
      original = Outcasted.fields[:size].dup
      original[:select_options] = :get_size_options
      output = Outcasted.new.outcast(:size, original, {input_name_prefix: 'data'})
      formated_options?(original, output)
    end

    it 'Formats options when it comes from a simple string' do
      original = Outcasted.fields[:size].dup
      original[:select_options] = [:small,:medium,:large]
      output = Outcasted.new.outcast(:size, original, {input_name_prefix: 'data'})
      assert_equal [ {description: 'Small', value: 'small'}, {description: 'Medium', value: 'medium'}, {description: 'Large', value: 'large'} ], output[:select_options]
    end

    it 'Selects the input value' do
      original = Outcasted.fields[:size]
      outcasted = Outcasted.new size: 'm'
      output = outcasted.outcast(:size, original, {input_name_prefix: 'data'})
      assert_equal 1, output[:select_options].select{|o|o[:selected]}.size
      assert output[:select_options].find{|o|o[:value]=='m'}[:selected]
    end

    it 'Adds [] at the end of input_name if multiple is true' do
      original = Outcasted.fields[:tags]
      output = Outcasted.new.outcast(:tags, original, {input_name_prefix: 'data'})
      assert_equal 'data[tags][]', output[:input_name]
    end

    it 'Selects multiple options when input_value is an array' do
      original = Outcasted.fields[:tags]
      outcasted = Outcasted.new tags: ['art','science']
      output = outcasted.outcast(:tags, original, {input_name_prefix: 'data'})
      assert output[:select_options].find{|o|o[:value]=='art'}[:selected]
      assert output[:select_options].find{|o|o[:value]=='science'}[:selected]
      refute output[:select_options].find{|o|o[:value]=='sport'}[:selected]
    end

    it 'Orders input values at the begining when multiple options' do
      original = Outcasted.fields[:related_properties]

      # Normal
      outcasted = Outcasted.new related_properties: ['prop3','prop1']
      output = outcasted.outcast(:related_properties, original, {input_name_prefix: 'data'})
      assert_equal 'prop3', output[:select_options][0][:value]
      assert output[:select_options][0][:selected]
      assert_equal 'prop1', output[:select_options][1][:value]
      assert output[:select_options][1][:selected]
      assert_equal 'prop2', output[:select_options][2][:value]
      refute output[:select_options][2][:selected]

      # When input_value is nil
      outcasted = Outcasted.new
      output = outcasted.outcast(:related_properties, original, {input_name_prefix: 'data'})
      assert_equal 'prop1', output[:select_options][0][:value]
      refute output[:select_options][0][:selected]
      assert_equal 'prop2', output[:select_options][1][:value]
      refute output[:select_options][1][:selected]
      assert_equal 'prop3', output[:select_options][2][:value]
      refute output[:select_options][2][:selected]

      # When input_value has a non existing value
      outcasted = Outcasted.new related_properties: ['stale','prop2']
      output = outcasted.outcast(:related_properties, original, {input_name_prefix: 'data'})
      assert_equal 'prop2', output[:select_options][0][:value]
      assert output[:select_options][0][:selected]
      assert_equal 'prop1', output[:select_options][1][:value]
      refute output[:select_options][1][:selected]
      assert_equal 'prop3', output[:select_options][2][:value]
      refute output[:select_options][2][:selected]
    end

  end

  describe '#outcast_price' do

    it 'Displays the price in dollars/pounds' do
      original = Outcasted.fields[:price]
      outcasted = Outcasted.new price: 2999
      output = outcasted.outcast(:price, original, {input_name_prefix: 'data'})
      assert_equal '29.99', output[:input_value]
    end

    it 'Leaves the field alone when value not an integer' do
      original = Outcasted.fields[:price]
      outcasted = Outcasted.new
      output = outcasted.outcast(:price, original, {input_name_prefix: 'data'})
      assert_nil outcasted.price
      assert_nil output[:input_value]
    end

  end

  describe '#outcast_attachment' do

    it 'Sets url' do
      original = Outcasted.fields[:pdf]
      outcasted = Outcasted.new
      output = outcasted.outcast(:pdf, original, {input_name_prefix: 'data'})
      assert_nil output[:url]

      outcasted.pdf = 'guidelines.pdf'
      output = outcasted.outcast(:pdf, original, {input_name_prefix: 'data'})
      assert_equal outcasted.attachment(:pdf).url, output[:url]
    end

    it 'Sets multiple if field is the batch field and document is new' do
      original = Outcasted.fields[:image]
      outcasted = Outcasted.new
      output = outcasted.outcast(:image, original, {input_name_prefix: 'data'})
      assert output[:multiple]
    end

    it 'Does not set multiple if there is no batch field' do
      original = OutcastedNoBatchField.fields[:image]
      outcasted = OutcastedNoBatchField.new
      output = outcasted.outcast(:image, original, {input_name_prefix: 'data'})
      refute output[:multiple]
    end

    it 'Does not set multiple if document is not new' do
      original = Outcasted.fields[:image]
      outcasted = Outcasted.new
      outcasted._is_new = false
      output = outcasted.outcast(:image, original, {input_name_prefix: 'data'})
      refute output[:multiple]
    end

    it 'Does not set multiple if field not the batch field' do
      original = Outcasted.fields[:pdf]
      outcasted = Outcasted.new
      output = outcasted.outcast(:pdf, original, {input_name_prefix: 'data'})
      refute output[:multiple]
    end

  end

end

