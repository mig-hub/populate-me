require 'helper'
require 'populate_me/document'

class Person < PopulateMe::Document
  field :name
  field :shared, type: :boolean
  field :age, type: :integer
  field :salary, type: :price
  field :dob, type: :date
  field :when, type: :datetime
end

describe PopulateMe::Document, 'Typecasting' do

  parallelize_me!

  let(:subject_class) { Person }
  subject { subject_class.new }

  describe "Value is blank or nil" do
    it "Returns nil" do
      assert_nil subject.typecast(:name,nil)
      assert_nil subject.typecast(:name,'')
      assert_nil subject.typecast(:salary,'')
      assert_nil subject.typecast(:dob,'')
      assert_nil subject.typecast(:when,'')
    end
  end

  describe "Field has type :string" do
    it "Returns it as-is" do
      assert_equal 'Bob', subject.typecast(:name,'Bob')
      assert_equal 'true', subject.typecast(:name,'true')
      assert_equal '5', subject.typecast(:name,'5')
    end
  end

  describe "Field has type :boolean" do
    it "Casts as a boolean" do
      assert_equal true, subject.typecast(:shared,'true')
      assert_equal false, subject.typecast(:shared,'false')
    end
  end

  describe "Field has type :integer" do
    describe "Value is just an integer" do
      it "Casts it as integer" do
        assert_equal 42, subject.typecast(:age,'42')
      end
    end
    describe "Value has something written at the end" do
      it "Ignores it" do
        assert_equal 42, subject.typecast(:age,'42 yo')
      end
    end
    describe "Value is a float" do
      it "Rounds it" do
        assert_equal 42, subject.typecast(:age,'42.50')
      end
    end
  end

  describe "Field has type :price" do
    describe "Value is an integer" do
      it "Casts it in cents/pence (x100)" do
        assert_equal 4200, subject.typecast(:salary,'42')
      end
    end
    describe "Value is a float with 2 decimals" do
      it "Casts it in cents/pence" do
        assert_equal 4250, subject.typecast(:salary,'42.50')
      end
    end
    describe "Value is a float with irregular decimals for a price" do
      it "Rounds it" do
        assert_equal 4250, subject.typecast(:salary,'42.5')
        assert_equal 4257, subject.typecast(:salary,'42.567')
      end
    end
    describe "Value is prefixed or suffixed" do
      it "Ignores what is not part of the price" do
        assert_equal 4250, subject.typecast(:salary,'$42.5')
        assert_equal 4250, subject.typecast(:salary,'42.5 Dollars')
      end
    end
  end

  describe "Field has type :date" do
    it "Parses the date with Date.parse" do
      assert_equal Date.parse('10/11/1979'), subject.typecast(:dob,'10/11/1979')
    end
    describe "Delimiter is a dash" do
      it "Replaces them with forward slash before parsing" do
        assert_equal Date.parse('10/11/1979'), subject.typecast(:dob,'10-11-1979')
      end
    end
    describe "Value is malformed" do
      it "Returns nil" do
        assert_nil subject.typecast(:dob,'10/11')
      end
    end
  end

  describe "Field has type :datetime" do
    it "Splits the numbers and feed them to Time.utc" do
      assert_equal Time.utc(1979,11,10,12,30,4), subject.typecast(:when,'10/11/1979 12:30:4')
    end
    describe "Delimiter is a dash" do
      it "Replaces them with forward slash before parsing" do
        assert_equal Time.utc(1979,11,10,12,30,4), subject.typecast(:when,'10-11-1979 12:30:4')
      end
    end
    describe "Value is malformed" do
      it "Returns nil" do
        assert_nil subject.typecast(:when,'10/11')
        assert_nil subject.typecast(:when,'10/11/1979')
      end
    end
  end

end
