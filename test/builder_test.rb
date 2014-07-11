# encoding: utf-8

require 'bacon'
$:.unshift File.expand_path('../../lib', __FILE__)
require "populate_me/builder"

describe 'PopulateMe::Builder' do

  def fragment(&block); PopulateMe::Builder.new(&block).to_s; end

  it "Builds simple tags" do
    fragment{ br }.should == '<br />'
    fragment{ p }.should == '<p />'
  end

  it "Opens and closes tags" do
    fragment{ p{} }.should == '<p></p>'
    fragment{ div{} }.should == '<div></div>'
  end

  it "Nests tags" do
    fragment{ p{ br } }.should == '<p><br /></p>'
  end

  it "Builds deeply nested tags" do
    fragment do
      p do
        div do
          ol do
            li
          end
        end
      end
    end.should == '<p><div><ol><li /></ol></div></p>'
  end

  it "Builds deeply nested tags with repetition" do
    fragment do 
      p do
        div do
          ol do
            li
            li
          end
          ol do
            li
            li
          end
        end
      end
    end.should == '<p><div><ol><li /><li /></ol><ol><li /><li /></ol></div></p>'
  end

  it "Builds deeply nested tags with strings" do
    fragment do
      p do
        div {'Hello, World'} 
      end
    end.should == '<p><div>Hello, World</div></p>'
  end
  
  it "Allows to write directly if needed" do
    fragment do
      write "<!DOCTYPE html>"
    end.should == '<!DOCTYPE html>'
  end

  it "Builds a full HTML page" do
    fragment do
      doctype
      html do
        head do
          title {"Hello World"}
        end
        body do
          h1 {"Hello World"}
        end
      end
    end.should == "<!DOCTYPE html>\n<html><head><title>Hello World</title></head><body><h1>Hello World</h1></body></html>"
  end

  it "Builds with some ruby inside" do
    fragment do
      table do
        tr do
          %w[one two three].each do |s|
            td{s}
          end
        end
      end
    end.should == '<table><tr><td>one</td><td>two</td><td>three</td></tr></table>'
  end

  it "Builds escapeable attributes" do
    fragment {
      a(:href => "http://example.org/?a=one&b=two") {
        "Click here"
      }
    }.should == "<a href='http:&#x2F;&#x2F;example.org&#x2F;?a=one&amp;b=two'>Click here</a>"
  end
  
  it "Should accept attributes in a string" do
    fragment{ input("type='text'") }.should == "<input type='text' />"
  end

  it 'Should accept symbols as attributes' do
    input = fragment{ input(:type => :text, :value => :one) }

    input.should =~ /type='text'/
    input.should =~ /value='one'/
  end

  it 'Builds tags with prefix' do
    fragment{ tag "prefix:local" }.should == '<prefix:local />'
  end

  it 'Builds tags with a variety of characters' do
    # with "-"
    fragment{ tag "hello-world" }.should == '<hello-world />'
    # with Hiragana
    fragment{ tag "あいうえお" }.should == '<あいうえお />'
  end
  
  it "Has a practicle way to add attributes like 'selected' based on boolean" do
    @selected = false
    fragment do
      option({:name => 'opt', :selected => @selected})
      option(:name => 'opt', :selected => !@selected)
      option(:name => 'opt', :selected => @i_am_nil)
    end.should == "<option name='opt' /><option name='opt' selected='true' /><option name='opt' />"
  end
  
  it "Builds a more complex HTML page with a variable in the outer scope" do
    
    default = 'HTML'
    
    html = PopulateMe::Builder.new do
      doctype
      html(:lang=>'en') do
        head { title { "My Choice" } }
        body do
          comment "Here starts the body"
          select(:name => 'language') do
            ['JS', 'HTML', 'CSS'].each do |l|
              option(:value => l, :selected => l==default) { l }
            end
          end
          write "\n<!-- This allows to write HTML directly when using a snippet -->\n"
          write "\n<!-- like Google Analytics or including another fragment -->\n"
        end
      end
    end.to_s
    
    html.should == "<!DOCTYPE html>\n<html lang='en'><head><title>My Choice</title></head><body>\n<!-- Here starts the body -->\n<select name='language'><option value='JS'>JS</option><option value='HTML' selected='true'>HTML</option><option value='CSS'>CSS</option></select>\n<!-- This allows to write HTML directly when using a snippet -->\n\n<!-- like Google Analytics or including another fragment -->\n</body></html>"
    
  end

  it 'Can be used inside the scope of an object' do
    class Stranger
      attr_accessor :name, :comment
      def show_comment
        PopulateMe::Builder.new(true) do |b|
          b.p{ self.comment }
        end.to_s
      end
      def show_summary
        PopulateMe::Builder.create_here do |b|
          b.article do
            b.h1{ self.name }
            b.p{ self.comment }
          end
        end
      end
      def fail_summary
        PopulateMe::Builder.create do
          article do
            h1{ self.name }
            p{ self.comment }
          end
        end
      end
    end

    s = Stranger.new
    s.name = 'The Doors'
    s.comment = 'Strange days'
    s.show_comment.should=='<p>Strange days</p>'
    s.show_summary.should=='<article><h1>The Doors</h1><p>Strange days</p></article>'
    s.fail_summary.should=="<article><h1><name /></h1><p>\n<!--  -->\n</p></article>"
  end

  describe 'Form helpers' do

    def builder_input_for obj, field, o={}
      PopulateMe::Builder.create{ input_for(obj, field, o) }
    end

    class Ticket
      attr_accessor :place, :price, :authorized, :position
      def up_or_down
        ['Up','Down']
      end
      def up_or_down_class
        [['Up','up_class'],['Down','down_class']]
      end
      def with_integer
        [3]
      end
      def with_multiple
        ['A','B']
      end
    end

    class BusTicket < Ticket
      def self.fields
        {
          place: {},
          price: {},
          authorized: {type: :boolean, form_field: false},
          position: {form_field: false}
        }
      end
    end

    it 'Builds no input for a field if the option is used' do
      ticket = Ticket.new
      builder_input_for(ticket,:place, form_field: false).should==''
    end

    it 'Can build string input' do
      ticket = Ticket.new
      builder_input_for(ticket, :place, wrap_input: false, type: :string).should=="<input type='text' name='data[place]' />"
      ticket.place = 'B52'
      builder_input_for(ticket, :place, wrap_input: false, type: :string).should=="<input type='text' name='data[place]' value='B52' />"
      builder_input_for(ticket, :place, wrap_input: false, type: :string, required: true).should=="<input type='text' name='data[place]' value='B52' required='true' />"
    end

    it 'Builds a string input by default if type is not specified' do
      ticket = Ticket.new
      builder_input_for(ticket, :place, wrap_input: false).should=="<input type='text' name='data[place]' />"
    end

    it 'Builds a string input by default if type is not recognized' do
      ticket = Ticket.new
      builder_input_for(ticket, :place, wrap_input: false, type: :unknown).should=="<input type='text' name='data[place]' />"
    end

    it 'Can send attributes to the default input type' do
      ticket = Ticket.new
      builder_input_for(
        ticket, :place, wrap_input: false, type: :integer,
        input_attributes: {type: :number, min: '0', max: '10', step: '1'}
      ).should=="<input type='number' name='data[place]' min='0' max='10' step='1' />"
    end

    it 'Can build a text input' do
      ticket = Ticket.new
      builder_input_for(ticket, :place, wrap_input: false, type: :text).should=="<textarea name='data[place]'></textarea>"
      ticket.place = "B\n5\n2"
      builder_input_for(ticket, :place, wrap_input: false, type: :text).should=="<textarea name='data[place]'>B\n5\n2</textarea>"
    end

    it 'Can build boolean inputs' do
      ticket = Ticket.new
      builder_input_for(ticket,:place, wrap_input: false, type: :boolean).should=="<input type='hidden' name='data[place]' value='false' /><input type='checkbox' name='data[place]' value='true' />"
      ticket.place = true
      builder_input_for(ticket,:place, wrap_input: false, type: :boolean).should=="<input type='hidden' name='data[place]' value='false' /><input type='checkbox' name='data[place]' value='true' checked='true' />"
    end

    it 'Can build select inputs' do
      ticket = Ticket.new
      builder_input_for(ticket, :place, wrap_input: false, type: :select, select_options: ['Yes','No']).should=="<select name='data[place]'><option value='Yes'>Yes</option><option value='No'>No</option></select>"
      ticket.place = 'Blah'
      builder_input_for(ticket, :place, wrap_input: false, type: :select, select_options: ['Yes','No']).should=="<select name='data[place]'><option value='Yes'>Yes</option><option value='No'>No</option></select>"
      ticket.place = 'Yes'
      builder_input_for(ticket, :place, wrap_input: false, type: :select, select_options: ['Yes','No']).should=="<select name='data[place]'><option value='Yes' selected='true'>Yes</option><option value='No'>No</option></select>"
    end

    it 'Can take the select options from a document method' do
      ticket = Ticket.new
      builder_input_for(ticket, :place, wrap_input: false, type: :select, select_options: :up_or_down).should=="<select name='data[place]'><option value='Up'>Up</option><option value='Down'>Down</option></select>"
    end

    it 'Keeps class of select options for comparison' do
      ticket = Ticket.new
      ticket.place = 3
      builder_input_for(ticket, :place, wrap_input: false, type: :select, select_options: :with_integer).should=="<select name='data[place]'><option value='3' selected='true'>3</option></select>"
      ticket.place = '3'
      builder_input_for(ticket, :place, wrap_input: false, type: :select, select_options: :with_integer).should=="<select name='data[place]'><option value='3'>3</option></select>"
    end

    it 'Can have the select option display something different from what is really sent' do
      ticket = Ticket.new
      builder_input_for(ticket, :place, wrap_input: false, type: :select, select_options: :up_or_down_class).should=="<select name='data[place]'><option value='up_class'>Up</option><option value='down_class'>Down</option></select>"
    end

    it 'Can build a multiple select input' do
      ticket = Ticket.new
      builder_input_for(ticket, :place, wrap_input: false, type: :select, select_options: :with_multiple, multiple: true).should=="<select name='data[place]' multiple='true'><option value='A'>A</option><option value='B'>B</option></select>"
      ticket.place = 'A'
      builder_input_for(ticket, :place, wrap_input: false, type: :select, select_options: :with_multiple, multiple: true).should=="<select name='data[place]' multiple='true'><option value='A' selected='true'>A</option><option value='B'>B</option></select>"
      ticket.place = ['A','B']
      builder_input_for(ticket, :place, wrap_input: false, type: :select, select_options: :with_multiple, multiple: true).should=="<select name='data[place]' multiple='true'><option value='A' selected='true'>A</option><option value='B' selected='true'>B</option></select>"
    end

    it 'Uses fields attributes as a start for the options when it exists' do
      ticket = BusTicket.new
      builder_input_for(ticket,:authorized).should==''
      builder_input_for(ticket,:authorized,form_field: true, wrap_input: false).should=="<input type='hidden' name='data[authorized]' value='false' /><input type='checkbox' name='data[authorized]' value='true' />"
    end

    # Can avoid escape HTML
    # Can be wrapped

  end

end

