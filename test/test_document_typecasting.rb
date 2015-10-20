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
      _(subject.typecast(:name,nil)).must_equal(nil)
      _(subject.typecast(:name,'')).must_equal(nil)
      _(subject.typecast(:salary,'')).must_equal(nil)
      _(subject.typecast(:dob,'')).must_equal(nil)
      _(subject.typecast(:when,'')).must_equal(nil)
    end
  end

  describe "Field has type :string" do
    it "Returns it as-is" do
      _(subject.typecast(:name,'Bob')).must_equal('Bob')
      _(subject.typecast(:name,'5')).must_equal('5')
    end
  end

  describe "Field has type :boolean" do
    it "Casts as a boolean" do
      _(subject.typecast(:shared,'true')).must_equal(true)
      _(subject.typecast(:shared,'false')).must_equal(false)
    end
  end

  describe "Field has type :integer" do
    describe "Value is just an integer" do
      it "Casts it as integer" do
        _(subject.typecast(:age,'42')).must_equal(42)
      end
    end
    describe "Value has something written at the end" do
      it "Ignores it" do
        _(subject.typecast(:age,'42 yo')).must_equal(42)
      end
    end
    describe "Value is a float" do
      it "Rounds it" do
        _(subject.typecast(:age,'42.50')).must_equal(42)
      end
    end
  end

  describe "Field has type :price" do
    describe "Value is an integer" do
      it "Casts it in cents/pence (x100)" do
        _(subject.typecast(:salary,'42')).must_equal(4200)
      end
    end
    describe "Value is a float with 2 decimals" do
      it "Casts it in cents/pence" do
        _(subject.typecast(:salary,'42.50')).must_equal(4250)
      end
    end
    describe "Value is a float with irregular decimals for a price" do
      it "Rounds it" do
        _(subject.typecast(:salary,'42.5')).must_equal(4250)
        _(subject.typecast(:salary,'42.567')).must_equal(4257)
      end
    end
    describe "Value is prefixed or suffixed" do
      it "Ignores what is not part of the price" do
        _(subject.typecast(:salary,'$42.5')).must_equal(4250)
        _(subject.typecast(:salary,'42.5 Dollars')).must_equal(4250)
      end
    end
  end

  describe "Field has type :date" do
    it "Parses the date with Date.parse" do
      _(subject.typecast(:dob,'10/11/1979')).must_equal(Date.parse('10/11/1979'))
    end
    describe "Delimiter is a dash" do
      it "Replaces them with forward slash before parsing" do
        _(subject.typecast(:dob,'10-11-1979')).must_equal(Date.parse('10/11/1979'))
      end
    end
    describe "Value is malformed" do
      it "Returns nil" do
        _(subject.typecast(:dob,'10/11')).must_equal(nil)
      end
    end
  end

  describe "Field has type :datetime" do
    it "Splits the numbers and feed them to Time.utc" do
      _(subject.typecast(:when,'10/11/1979 12:30:4')).must_equal(Time.utc(1979,11,10,12,30,4))
    end
    describe "Delimiter is a dash" do
      it "Replaces them with forward slash before parsing" do
        _(subject.typecast(:when,'10-11-1979 12:30:4')).must_equal(Time.utc(1979,11,10,12,30,4))
      end
    end
    describe "Value is malformed" do
      it "Returns nil" do
        _(subject.typecast(:when,'10/11')).must_equal(nil)
        _(subject.typecast(:when,'10/11/1979')).must_equal(nil)
      end
    end
  end

end
