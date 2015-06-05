require 'populate_me/document'

class Person < PopulateMe::Document
  field :name
  field :shared, type: :boolean
  field :age, type: :integer
  field :salary, type: :price
  field :dob, type: :date
  field :when, type: :datetime
end

RSpec.describe PopulateMe::Document, 'Typecasting' do

  let(:subject_class) { Person }
  subject { subject_class.new }

  context "Value is blank or nil" do
    it "Returns nil" do
      expect(subject.typecast(:name,nil)).to eq(nil)
      expect(subject.typecast(:name,'')).to eq(nil)
      expect(subject.typecast(:salary,'')).to eq(nil)
      expect(subject.typecast(:dob,'')).to eq(nil)
      expect(subject.typecast(:when,'')).to eq(nil)
    end
  end

  context "Field has type :string" do
    it "Returns it as-is" do
      expect(subject.typecast(:name,'Bob')).to eq('Bob')
      expect(subject.typecast(:name,'5')).to eq('5')
    end
  end

  context "Field has type :boolean" do
    it "Casts as a boolean" do
      expect(subject.typecast(:shared,'true')).to eq(true)
      expect(subject.typecast(:shared,'false')).to eq(false)
    end
  end

  context "Field has type :integer" do
    context "Value is just an integer" do
      it "Casts it as integer" do
        expect(subject.typecast(:age,'42')).to eq(42)
      end
    end
    context "Value has something written at the end" do
      it "Ignores it" do
        expect(subject.typecast(:age,'42 yo')).to eq(42)
      end
    end
    context "Value is a float" do
      it "Rounds it" do
        expect(subject.typecast(:age,'42.50')).to eq(42)
      end
    end
  end

  context "Field has type :price" do
    context "Value is an integer" do
      it "Casts it in cents/pence (x100)" do
        expect(subject.typecast(:salary,'42')).to eq(4200)
      end
    end
    context "Value is a float with 2 decimals" do
      it "Casts it in cents/pence" do
        expect(subject.typecast(:salary,'42.50')).to eq(4250)
      end
    end
    context "Value is a float with irregular decimals for a price" do
      it "Rounds it" do
        expect(subject.typecast(:salary,'42.5')).to eq(4250)
        expect(subject.typecast(:salary,'42.567')).to eq(4257)
      end
    end
    context "Value is prefixed or suffixed" do
      it "Ignores what is not part of the price" do
        expect(subject.typecast(:salary,'$42.5')).to eq(4250)
        expect(subject.typecast(:salary,'42.5 Dollars')).to eq(4250)
      end
    end
  end

  context "Field has type :date" do
    it "Parses the date with Date.parse" do
      expect(subject.typecast(:dob,'10/11/1979')).to eq(Date.parse('10/11/1979'))
    end
    context "Delimiter is a dash" do
      it "Replaces them with forward slash before parsing" do
        expect(subject.typecast(:dob,'10-11-1979')).to eq(Date.parse('10/11/1979'))
      end
    end
    context "Value is malformed" do
      it "Returns nil" do
        expect(subject.typecast(:dob,'10/11')).to eq(nil)
      end
    end
  end

  context "Field has type :datetime" do
    it "Splits the numbers and feed them to Time.utc" do
      expect(subject.typecast(:when,'10/11/1979 12:30:4')).to eq(Time.utc(1979,11,10,12,30,4))
    end
    context "Delimiter is a dash" do
      it "Replaces them with forward slash before parsing" do
        expect(subject.typecast(:when,'10-11-1979 12:30:4')).to eq(Time.utc(1979,11,10,12,30,4))
      end
    end
    context "Value is malformed" do
      it "Returns nil" do
        expect(subject.typecast(:when,'10/11')).to eq(nil)
        expect(subject.typecast(:when,'10/11/1979')).to eq(nil)
      end
    end
  end

end
