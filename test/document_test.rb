require 'bacon'
$:.unshift File.expand_path('../../lib', __FILE__)
require 'populate_me/document'

describe 'PopulateMe::Document' do

  # PopulateMe::Document is the base for any document
  # the Backend is supposed to deal with.
  #
  # Any module for a specific ORM or ODM should include
  # this module first.
  # It contains what is not specific to a particular kind
  # of database and it provides defaults.
  #
  # It can be used on its own but it keeps everything
  # in memory. Which means it is only for tests and conceptual
  # understanding.

  describe 'Descriptive methods' do

    class Catalogue
      include PopulateMe::Document
    end
    class Catalogue::Chapter
      include PopulateMe::Document
    end
    class Catalogue::Chapter::AttachedFile
      include PopulateMe::Document
      attr_accessor :name, :size
      label :name
    end

    it 'Has a friendly name on Class::to_s' do
      Catalogue::Chapter::AttachedFile.name.should=='Catalogue::Chapter::AttachedFile'
      Catalogue::Chapter::AttachedFile.to_s.should=='Catalogue Chapter Attached File'
    end

    it 'Has a version for name without modules' do
      Catalogue.to_s_short.should=='Catalogue'
      Catalogue::Chapter::AttachedFile.to_s_short.should=='Attached File'
    end

    it 'Has a plural version which only adds a `s` by default' do
      Catalogue::Chapter::AttachedFile.to_s_plural.should=='Catalogue Chapter Attached Files'
    end

    it 'Uses the label variable as a description for instances when there is one' do
      file = Catalogue::Chapter::AttachedFile.new
      file.name = 'file.pdf'
      file.size = '300KB'
      file.to_s.should=='file.pdf'
    end

    it 'Uses a default name instead when the label field is blank or not set' do
      file = Catalogue::Chapter::AttachedFile.new
      file.to_s.should==file.inspect
      Catalogue::Chapter::AttachedFile.label_field = nil
      file.to_s.should==file.inspect
    end

  end

  class Couch
    include PopulateMe::Document
    field :colour, required: true
    field :capacity, type: :integer, wrap: false
    field :price, type: :price, required: true
    field :places, type: :list, max: 5
    field :seats, type: :list, class_name: '::Place', max: 5
    field :available, type: :boolean
    field :position, type: :position
    field :secret, type: :hidden, label: 'Shhh...'
    field :two_words, input_attributes: {name: 'joe'}
    field :summary, type: :text
  end

  class Couch::Place
    include PopulateMe::Document
    field :position, type: :integer
  end

  class FieldlessDoc
    include PopulateMe::Document
    attr_accessor :name
  end

  describe 'Fields' do

    it 'Defaults fields to an empty hash' do
      FieldlessDoc.fields.should=={}
    end

    it 'Can declare fields and options about them in one go' do
      Couch.fields.size.should==11
      Couch.fields.keys.should==[:id, :colour, :capacity, :price, :places, :seats, :available, :position, :secret, :two_words, :summary]
      Couch.fields[:available][:type].should==:boolean
      Couch.fields[:price][:required].should==true
      Couch.fields[:price][:field_name].should==:price
    end

    it 'Sets which fields should be removed from a form by default' do
      Couch.fields[:colour][:form_field].should==true
      Couch.fields[:id][:form_field].should==false
      Couch.fields[:position][:form_field].should==false
    end

    it 'Sets which fields should be wrapped with a label by default in forms' do
      Couch.fields[:colour][:wrap].should==true
      Couch.fields[:position][:wrap].should==false
      Couch.fields[:capacity][:wrap].should==false
      Couch.fields[:places][:wrap].should==false
      Couch.fields[:secret][:wrap].should==false
    end

    it 'Sets labels when not provided' do
      Couch.fields[:secret][:label].should=='Shhh...'
      Couch.fields[:two_words][:label].should=='Two Words'
    end

    it 'Creates attribute accessors for fields' do
      couch = Couch.new
      couch.price = 300
      couch.price.should==300
    end

    it 'Uses the first field as label when label field is not specified' do
      couch = Couch.new
      couch.colour = 'White'
      couch.to_s.should=='White'
      Couch.label_field = :capacity
      couch.to_s.should==couch.inspect
    end

    it 'Can declare list fields' do
      Couch.fields[:places][:max].should==5
      couch = Couch.new
      couch.places << Couch::Place.new
      couch.places.size.should==1
      couch = Couch.new
      couch.places.should==[]
    end

    it 'Uses Utils.guess_related_class_name to set class_name of list fields' do
      Couch.fields[:places][:class_name].should=='Couch::Place'
      Couch.fields[:seats][:class_name].should=='Couch::Place'
      Couch.fields[:seats][:dasherized_class_name].should=='couch--place'
    end

    it 'Makes sure :input_attributes is a hash except for list' do
      Couch.fields[:price][:input_attributes].should=={type: :text}
      Couch.fields[:two_words][:input_attributes].should=={name:'joe', type: :text}
      Couch.fields[:secret][:input_attributes].should=={type: :hidden}
      Couch.fields[:summary][:input_attributes].should=={}
      Couch.fields[:seats][:input_attributes].should==nil
    end

  end

  class Casanova
    include PopulateMe::Document
    relationship :girlfriends, max: 42
    relationship :babes, class_name: '::Girlfriend', label: 'Babies', foreign_key: 'casanova_id'
  end

  class RelationshiplessDoc
    include PopulateMe::Document
    attr_accessor :name
  end

  describe 'Relationships' do

    it 'Defaults relationships to an empty hash' do
      RelationshiplessDoc.relationships.should=={}
    end

    it 'Records relationships and their options' do
      Casanova.relationships.size.should==2
      Casanova.relationships[:girlfriends][:max].should==42
    end

    it 'Should guess the class_name using Utils.guess_related_class_name' do
      Casanova.relationships[:girlfriends][:class_name].should=='Casanova::Girlfriend'
      Casanova.relationships[:babes][:class_name].should=='Casanova::Girlfriend'
    end

    it 'Should guess a label when not provided' do
      Casanova.relationships[:girlfriends][:label].should=='Girlfriends'
      Casanova.relationships[:babes][:label].should=='Babies'
    end

    it 'Should guess a foreign_key when not provided and make it a symbol' do
      Casanova.relationships[:girlfriends][:foreign_key].should==:casanova_id
      Casanova.relationships[:babes][:foreign_key].should==:casanova_id
    end

  end

  describe 'Typecasting' do

    # We typecast values which come from post requests, a CVS file or the like.
    # Not sure these methods need to be instance methods but just in case...

    class Outcast
      include PopulateMe::Document
      field :name
      field :shared, type: :boolean
      field :age, type: :integer
      field :salary, type: :price
      field :dob, type: :date
      field :when, type: :datetime
    end

    it 'Uses automatic or specific typecast when relevant' do
      Outcast.new.typecast(:name,nil).should==nil
      Outcast.new.typecast(:name,'').should==nil
      Outcast.new.typecast(:name,'Bob').should=='Bob'
      Outcast.new.typecast(:name,'5').should=='5'
      Outcast.new.typecast(:shared,'true').should==true
      Outcast.new.typecast(:shared,'false').should==false
      Outcast.new.typecast(:age,'42').should==42
      Outcast.new.typecast(:age,'42 yo').should==42
      Outcast.new.typecast(:age,'42.50').should==42
      Outcast.new.typecast(:salary,'42').should==4200
      Outcast.new.typecast(:salary,'42.50').should==4250
      Outcast.new.typecast(:salary,'42.5').should==4250
      Outcast.new.typecast(:salary,'$42.5').should==4250
      Outcast.new.typecast(:salary,'42.5 Dollars').should==4250
      Outcast.new.typecast(:salary,'').should==nil
      Outcast.new.typecast(:dob,'').should==nil
      Outcast.new.typecast(:dob,'10/11').should==nil
      Outcast.new.typecast(:dob,'10/11/1979').should==Date.parse('10/11/1979')
      Outcast.new.typecast(:dob,'10-11-1979').should==Date.parse('10/11/1979')
      Outcast.new.typecast(:when,'').should==nil
      Outcast.new.typecast(:when,'10/11').should==nil
      Outcast.new.typecast(:when,'10/11/1979').should==nil
      Outcast.new.typecast(:when,'10/11/1979 12:30:4').should==Time.utc(1979,11,10,12,30,4)
      Outcast.new.typecast(:when,'10-11-1979 12:30:4').should==Time.utc(1979,11,10,12,30,4)
    end

  end

  class Egg
    include PopulateMe::Document
    attr_accessor :size, :taste, :_hidden
  end

  class AmazingEgg
    include PopulateMe::Document
    attr_accessor :hidden, :_hidden
    field :size
    field :taste
    field :_special
  end

  describe 'Initializing and setting' do

    it 'Can set variables with a hash' do
      obj = Egg.new
      obj.set size: 1, taste: 'good'
      obj.size.should==1
      obj.taste.should=='good'
    end

    it 'Can set variables with string keys' do
      obj = Egg.new
      obj.set 'size'=>4, 'taste'=>'good'
      obj.size.should==4
      obj.taste.should=='good'
    end

    it 'Cannot set variables without an accessor' do
      obj = Egg.new
      lambda{ obj.set color: 'blue' }.should.raise(NoMethodError)
    end

    it 'Can set values when initializing' do
      obj = Egg.new size: 1, taste: 'good'
      obj.size.should==1
      obj.taste.should=='good'
      obj.new?.should==true
    end

    it 'Can set _is_new when initializing' do
      obj = Egg.new size: 1, taste: 'good', _is_new: false
      obj.size.should==1
      obj.taste.should=='good'
      obj.new?.should==false
    end

    it 'When fields are not declared, only variables which do not start with _ are persisted' do
      obj = Egg.new size: 3, _hidden: 'secret'
      obj.size.should==3
      obj.taste.should==nil
      obj._hidden.should=='secret'
      obj.persistent_instance_variables.should==[:@size]
    end

    it 'When fields are declared, it knows which variables to persist' do
      obj = AmazingEgg.new size: 3, _special: 'Yellow', hidden: 'secret', _hidden: 'secret too'
      obj.size.should==3
      obj.taste.should==nil
      obj._special.should=='Yellow'
      obj.hidden.should=='secret'
      obj._hidden.should=='secret too'
      obj.persistent_instance_variables.include?(:@size).should==true
      obj.persistent_instance_variables.include?(:@_special).should==true
    end

    it 'Turns into a hash with string keys' do
      obj = Egg.new
      obj.to_h.should=={'_class'=>'Egg'}
      obj.set size: 1, taste: 'good', _hidden: 'secret'
      obj._hidden.should=='secret'
      obj.to_h.should=={'size'=>1,'taste'=>'good','_class'=>'Egg'}
      obj.to_h.should==obj.to_hash
    end

  end

  describe 'Set Defaults' do

    class Tap
      include PopulateMe::Document
      field :status, default: 'closed'
      field :proc_status, default: proc{'closed'}
      field :method_status, default: :status
      field :brand
    end

    it 'Should set the declared fields which have a :default option' do
      tap = Tap.new.set_defaults
      tap.status.should=='closed'
      tap.proc_status.should=='closed'
      tap.method_status.should=='closed'
      tap.brand.should==nil
    end

    it 'Should only overwrite a field if it is nil unless forced' do
      tap = Tap.new(status: 'open').set_defaults
      tap.status.should=='open'
      tap.set_defaults(force: true)
      tap.status.should=='closed'
    end

  end

  describe 'Callbacks' do

    class Hamburger
      include PopulateMe::Document
      attr_accessor :taste

      register_callback :layers, :bread
      register_callback :layers, :cheese
      register_callback :layers do
        self.taste
      end

      register_callback :after_cook, :add_salad
      register_callback :after_cook do
        taste << ' with more cheese'
      end
      def add_salad
        taste << ' with salad'
      end

      register_callback :after_eat do
        taste << ' stomach'
      end
      register_callback :after_eat, prepend: true do
        taste << ' my'
      end
      register_callback :after_eat, :prepend_for, prepend: true
      def prepend_for
        taste << ' for'
      end

      before :digest do
        taste << ' taste'
      end
      before :digest, :add_dot
      before :digest, prepend: true do
        taste << ' the'
      end
      before :digest, :prepend_was, prepend: true
      after :digest do
        taste << ' taste'
      end
      after :digest, :add_dot
      after :digest, prepend: true do
        taste << ' the'
      end
      after :digest, :prepend_was, prepend: true
      def add_dot; taste << '.'; end
      def prepend_was; taste << ' was'; end

      before :argument do |name|
        taste << " #{name}"
      end
      after :argument, :after_with_arg
      def after_with_arg(name)
        taste << " #{name}"
      end
    end

    it 'Registers callbacks as symbols or blocks' do
      Hamburger.callbacks[:layers].size.should==3
      Hamburger.callbacks[:layers][0].should==:bread
      Hamburger.callbacks[:layers][1].should==:cheese
      h = Hamburger.new taste: 'good'
      h.instance_eval(&Hamburger.callbacks[:layers][2]).should=='good'
    end

    it 'Executes symbol or block callbacks' do
      h = Hamburger.new taste: 'good'
      h.exec_callback('after_cook').taste.should=='good with salad with more cheese'
    end

    it 'Does not raise if executing a callback which does not exist' do
      h = Hamburger.new taste: 'good'
      h.exec_callback(:after_burn).taste.should=='good'
    end

    it 'Has an option to prepend when registering callbacks' do
      h = Hamburger.new taste: 'good'
      h.exec_callback(:after_eat).taste.should=='good for my stomach'
    end

    it 'Has callback shortcuts for before and after' do
      h = Hamburger.new taste: 'good'
      h.exec_callback(:before_digest).taste.should=='good was the taste.'
      h.taste = 'good'
      h.exec_callback(:after_digest).taste.should=='good was the taste.'
    end

    it 'Optionally takes the callback name as an argument' do
      h = Hamburger.new taste: 'good'
      h.exec_callback(:before_argument).taste.should=='good before_argument'
      h.exec_callback(:after_argument).taste.should=='good before_argument after_argument'
    end

  end

  class User
    include PopulateMe::Document
    attr_accessor :first_name, :last_name
  end

  describe 'Creation' do

    it 'Can be saved as raw hash' do
      User.documents.should==[] # Empty by default
      u = User.new first_name: 'Bob', last_name: 'Mould'
      u.perform_create
      u.first_name.should=='Bob'
      User.documents.size.should==1
      User.documents[0].should==u.to_h # Data is the hash
    end

  end

  describe 'Creation From Hash' do

    class Tomato
      include PopulateMe::Document
      attr_accessor :taste
    end

    it 'Can be recreated from the hash saved' do
      tom = Tomato.new taste: 'good'
      tom.perform_create
      Tomato.documents[0].should==tom.to_h
      retrieved = Tomato.from_hash(Tomato.documents[0])
      retrieved.new?.should==false
      retrieved.should==tom
    end

    it 'Can mark the document as new or not when recreating from hash' do
      retrieved = Tomato.from_hash(Tomato.documents[0].merge('_is_new'=>true))
      retrieved.new?.should==true
      retrieved.to_h.should==Tomato.documents[0]
    end

    it 'Raises if trying to create from something that is not a Hash' do
      lambda{Tomato.from_hash(nil)}.should.raise(TypeError)
      lambda{Tomato.from_hash(42)}.should.raise(TypeError)
    end

    # it 'Can be created from Post' do
    # end

  end

  class Garlic
    include PopulateMe::Document
    attr_accessor :strength, :shape, :bags
    def bags; @bags ||= []; end
  end

  class Garlic::Bag
    include PopulateMe::Document
    attr_accessor :index
  end

  describe 'Update' do

    it 'Raises on update if the original does not exist' do
      g = Garlic.new id: 'xxx', strength: 5
      lambda{ g.perform_update }.should.raise(PopulateMe::MissingDocumentError)
    end

    it 'Raises on update if the document has no ID' do
      g = Garlic.new id: 'xxx', strength: 3
      g.perform_create
      g.id = nil
      lambda{ g.perform_update }.should.raise(PopulateMe::MissingDocumentError)
    end

    it 'Updates correctly' do
      g = Garlic.new id: 'xxx', shape: 'curvy'
      g.perform_update
      Garlic.documents[0]['shape'].should=='curvy'
      Garlic.documents[0]['strength'].should==nil
    end

  end

  describe 'Update From Hash' do

    it 'Clears the list fields before updating them' do
      g = Garlic.new.set_from_hash({
        'shape'=>'cone',
        'strength'=>3,
        'bags'=> [
          {'_class'=>'Garlic::Bag', 'index'=>0}
        ]
      })
      g.shape.should=='cone'
      g.bags.count.should==1
      g.bags[0].class.name.should=='Garlic::Bag'
      g.bags[0].index.should==0
      g.set_from_hash({
        'bags'=> [
          {'_class'=>'Garlic::Bag', 'index'=>4}
        ]
      })
      g.shape.should=='cone'
      g.bags.count.should==1
      g.bags[0].index.should==4
    end

  end

  class Ball
    include PopulateMe::Document
    attr_accessor :diameter
  end

  describe 'Deletion' do

    it 'Raises on delete if the entry does not exist' do
      b = Ball.new id: 'xxx', diameter: 5
      lambda{ b.perform_delete }.should.raise(PopulateMe::MissingDocumentError)
    end

    it 'Raises on delete if the document has no ID' do
      b = Ball.new id: 'xxx', diameter: 3
      b.perform_create
      b.id = nil
      lambda{ b.perform_delete }.should.raise(PopulateMe::MissingDocumentError)
    end

    it 'Deletes correctly' do
      b = Ball.new id: 'yyy', diameter: 5
      b.perform_create
      Ball.documents.find{|d| d['id']=='yyy' }.should!=nil
      b.perform_delete
      Ball.documents.find{|d| d['id']=='yyy' }.should==nil
    end

  end

  class Haircut
    include PopulateMe::Document
    attr_accessor :name
  end

  class SpecialHaircut
    include PopulateMe::Document
    field :name, type: :id
    field :height
  end

  describe 'Comparison' do

    it 'Consider equal 2 documents with the same data' do
      Haircut.new.should==Haircut.new
      Haircut.new(name: 'shaved').should==Haircut.new(name: 'shaved')
      Haircut.new.should!=nil
      Haircut.new.should!=String.new
    end

  end

  describe 'Find by ID' do

    it 'Has a class method to get the entry of a specific ID as an object' do
      Haircut.new(id: 123, name: 'pigtails').perform_create
      Haircut.new(id: '123', name: 'spikes').perform_create
      Haircut.admin_get(123).name.should=='pigtails'
      Haircut.admin_get('123').name.should=='spikes'
      SpecialHaircut.id_string_key.should=='name'
      SpecialHaircut.new(name:'mohawk',height:3).perform_create
      SpecialHaircut.admin_get('mohawk').height.should==3
    end

    it 'Returns nil if document does not exist' do
      Haircut.admin_get('abc').should==nil
    end

  end

  describe 'Find' do

    it 'Finds everything by default' do
      Haircut.admin_find.size.should==2
    end

    it 'Uses the :query option for filtering' do
      Haircut.admin_find(query: {name: 'pigtails'}).size.should==1
      Haircut.admin_find(query: {name: 'pigtails', id: 'bar'}).size.should==0
    end

  end

  describe 'Default Sorting' do

    class Soldier
      include PopulateMe::Document
      attr_accessor :name, :position
    end
    Soldier.new(name: 'Bob', position: 2).perform_create
    Soldier.new(name: 'Albert', position: 3).perform_create
    Soldier.new(name: 'Tony', position: 1).perform_create

    it 'Uses the key and direction passed to Doc::sort_by on Doc::admin_find' do
      Soldier.sort_by(:name).admin_find[0].name.should=='Albert'
      Soldier.sort_by(:name,:desc).admin_find[0].name.should=='Tony'
      Soldier.sort_by(:position).admin_find[0].position.should==1
    end

    it 'Raises ArgumentError when second argument is not :asc or :desc' do
      lambda{ Soldier.sort_by(:name,0) }.should.raise(ArgumentError)
    end

    it 'Raises ArgumentError when the key does not exist' do
      lambda{ Soldier.sort_by(:namespace) }.should.raise(ArgumentError)
    end

  end

  describe 'Manual Sorting' do

    class Champion
      include PopulateMe::Document
      field :position, type: :position
      field :scoped_position, type: :position, scope: :team_id
    end
    Champion.new(id:'a').perform_create
    Champion.new(id:'b').perform_create
    Champion.new(id:'c').perform_create

    it 'Sets the indexes on the provided field' do
      Champion.set_indexes(:position,['b','a','c'])
      Champion.admin_get('a').position.should==1
      Champion.admin_get('b').position.should==0
      Champion.admin_get('c').position.should==2
    end

    it 'Determines which field is a sort field for a given request' do
      no_filter = {params: {}}
      scoped_filter = {params: {filter: {'team_id'=>'the a team'}}}
      irrelevant_scope_filter = {params: {filter: {'employer_id'=>'the a team'}}}
      overscoped_filter = {params: {filter: {'team_id'=>'the a team','extra'=>'extra'}}}
      Champion.sort_field_for(no_filter).should==:position
      Champion.sort_field_for(scoped_filter).should==:scoped_position
      Champion.sort_field_for(irrelevant_scope_filter).should==nil
      Champion.sort_field_for(overscoped_filter).should==nil
    end

  end

  class Dodgy
    include PopulateMe::Document
    attr_accessor :prohibited, :number, :_log
    def validate
      self.number = self.number.to_i unless self.number.is_a? Integer
      error_on(:number, 'Is too high') if self.number==15
      error_on(:prohibited,'Is not allowed') unless prohibited.nil?
      error_on(:prohibited,'Is not good') unless prohibited.nil?
    end
    before :validate do
      @_log ||= ''
      @_log << self.errors.size.to_s
    end
    after :validate do
      @_log ||= ''
      @_log << self.errors.size.to_s
    end
  end

  describe 'Validation' do

    it 'Handles validations' do
      u = Dodgy.new
      u.errors.should=={}
      u.valid?.should==true
      u.prohibited = 'I dare'
      u.valid?.should==false
      u.errors[:prohibited].should==['Is not allowed','Is not good']
      u.prohibited = nil
      u.valid?.should==true
      u.number = 15
      u.number.should==15
      u.valid?.should==false
    end

    it 'Uses callbacks around validation' do
      d = Dodgy.new prohibited: 'I dare'
      d.valid?.should==false
      d._log.should=='01'
    end

  end

  class Death
    include PopulateMe::Document
    attr_accessor :pain_level, :was_alive, :is_dead
    before :delete do
      @was_alive = !self.class.admin_get(self.id).nil?
    end
    after :delete do
      @is_dead = self.class.admin_get(self.id).nil?
    end
  end

  class Parent
    include PopulateMe::Document
    field :name
    relationship :children, class_name: :child
    relationship :vagrants, dependent: false
  end
  class Parent::Child
    include PopulateMe::Document
    field :name
    field :parent_id, type: :hidden
  end
  class Parent::Vagrant
    include PopulateMe::Document
    field :name
    field :parent_id, type: :hidden
  end

  describe 'High level deletion' do

    it 'Uses callbacks on the high level deletion method' do
      death = Death.new pain_level: 5, id: '123'
      death.perform_create
      death._is_new = false
      Death.admin_get('123').pain_level.should==5
      death.delete
      death.new?.should==true
      Death.admin_get('123').should==nil
      death.was_alive.should==true
      death.is_dead.should==true
    end

    it 'Destroy related document when they are dependent' do
      p = Parent.new(id:'1',name:'joe')
      p.save
      c1 = Parent::Child.new(id:'1',name:'bob1',parent_id:'1')
      c1.save
      c2 = Parent::Child.new(id:'2',name:'bob2',parent_id:'1')
      c2.save
      Parent::Child.admin_get('1').should!=nil
      Parent::Child.admin_get('2').should!=nil
      v1 = Parent::Vagrant.new(id:'1',name:'bob1',parent_id:'1')
      v1.save
      v2 = Parent::Vagrant.new(id:'2',name:'bob2',parent_id:'1')
      v2.save
      Parent::Vagrant.admin_get('1').should!=nil
      Parent::Vagrant.admin_get('2').should!=nil
      p.delete
      Parent::Child.admin_get('1').should==nil
      Parent::Child.admin_get('2').should==nil
      Parent::Vagrant.admin_get('1').should!=nil
      Parent::Vagrant.admin_get('2').should!=nil
    end

  end

  class SuperHero
    include PopulateMe::Document
    attr_accessor :name, :power, :_log
    def validate
      error_on(:power,'Needed') if power.nil?
    end

    before(:save) { @_log = '' }
    before(:create) { @_log << 'Just ' }
    after(:create) { @_log << 'born' }
    before(:update) { @_log << 'Now ' }
    after(:update) { @_log << 'updated' }
    after(:save) { @_log << '.' }
  end

  describe 'High level saving' do

    it 'Creates or updates depending on if the document is new or not' do
      hero = SuperHero.new name: 'Hulk', power: 'anger'
      hero.save
      SuperHero.documents.size.should==1
      hero.power = 'uncontrolled anger'
      hero.save
      SuperHero.documents.size.should==1
      SuperHero.documents[0]['power'].should=='uncontrolled anger'
    end

    it 'Does not save if the document is not valid' do
      hero = SuperHero.new id: 'spidey', name: 'Spiderman'
      hero.valid?.should==false
      hero.save
      SuperHero.admin_get('spidey').should==nil
    end

    it 'Uses the callbacks' do
      hero = SuperHero.new name: 'Torch', power: 'fire'
      hero.save
      hero.id.should!=nil
      hero.new?.should==false
      hero._log.should=='Just born.'
      hero.power = 'flying fire'
      hero.save
      hero._log.should=='Now updated.'
    end

  end

  describe 'Composite document' do

    class CookBook
      include PopulateMe::Document
      attr_accessor :title
      def recipes; @recipes ||= []; end
      EXAMPLE = {
        '_class'=>'CookBook',
        'title'=>'Cakes',
        'recipes'=>[
          {
            '_class'=>'CookBook::Recipe',
            'name'=>'Chocolate Cake',
            'ingredients'=>[{'name'=>'Chocolate','_class'=>'CookBook::Recipe::Ingredient'}]
          },
          {
            '_class'=>'CookBook::Recipe',
            'name'=>'Pound Cake',
            'ingredients'=>[{'name'=>'Egg','_class'=>'CookBook::Recipe::Ingredient'}]
          }
        ]
      }
      before :cook, :recurse_callback
    end
    class CookBook::Recipe
      include PopulateMe::Document
      attr_accessor :name, :_log
      def ingredients; @ingredients ||= []; end
      before :cook, :recurse_callback
      before :cook do
        @_log = 'Learn'
      end
    end
    class CookBook::Recipe::Ingredient
      include PopulateMe::Document
      attr_accessor :name, :_log
      def validate
        error_on(:name,'Dangerous') if self.name=='Poison'
      end
      before :cook do
        @_log = 'Smell'
      end

      [:save,:create,:update,:delete].each do |cb|
        before cb, :log_cb
        after cb, :log_cb
      end
      def log_cb name
        @_log ||= ''
        @_log << "#{name} "
      end
    end

    it 'Turns into a hash with string keys' do
      book = CookBook.new title: 'Cakes'
      rcp1 = CookBook::Recipe.new name: 'Chocolate Cake'
      rcp2 = CookBook::Recipe.new name: 'Pound Cake'
      choc = CookBook::Recipe::Ingredient.new name: 'Chocolate'
      egg = CookBook::Recipe::Ingredient.new name: 'Egg'
      rcp1.ingredients << choc
      rcp2.ingredients << egg
      book.recipes << rcp1
      book.recipes << rcp2
      book.to_h.should==CookBook::EXAMPLE
    end

    it 'Can be recreated from the hash saved' do
      book = CookBook.from_hash(CookBook::EXAMPLE)
      book.title.should=='Cakes'
      book.recipes[1].name.should=='Pound Cake'
      book.recipes[1].ingredients[0].name=='Egg'
    end

    it 'Validates a document if nested documents are valid' do
      book = CookBook.from_hash(CookBook::EXAMPLE)
      book.recipes[0].ingredients[0].valid?.should==true
      book.recipes[0].valid?.should==true
      book.valid?.should==true
    end

    it 'Does not validate a document if nested documents are not valid' do
      book = CookBook.from_hash(CookBook::EXAMPLE)
      book.recipes[0].ingredients[0].name = 'Poison'
      book.recipes[0].ingredients[0].valid?.should==false
      book.recipes[0].valid?.should==false
      book.valid?.should==false
    end

    it 'Has a special method for recursively execute a callback' do
      book = CookBook.from_hash(CookBook::EXAMPLE)
      book.recipes[0].ingredients[0]._log.should==nil
      book.recipes[0]._log.should==nil
      book.exec_callback(:before_cook)
      book.recipes[0].ingredients[0]._log.should=='Smell'
      book.recipes[0]._log.should=='Learn'
    end

    it 'Has all the default recursive callbacks registered' do
      # [:save,:create,:update].each do |cb|
      #   CookBook.callbacks["before_#{cb}".to_sym].include?(:recurse_callback).should==true
      #   CookBook.callbacks["after_#{cb}".to_sym].include?(:recurse_callback).should==true
      # end
      book = CookBook.from_hash(CookBook::EXAMPLE)
      expected_log = ''
      [:save,:create,:update,:delete].each do |cb|
        [:before, :after].each do |when_cb|
          book.exec_callback("#{when_cb}_#{cb}")
          expected_log << "#{when_cb}_#{cb} "
        end
      end
      book.recipes[0].ingredients[0]._log.should==expected_log
    end

  end

  describe 'Admin related methods' do

    class SuperHeroTeam
      include PopulateMe::Document
      field :name
      field :score, form_field: false
      field :active, type: :boolean, wrap: false
      field :members, type: :list
      field :dropdown1, type: :select, select_options: [{description: 'Yes', value: 'yes'}, {description: 'No', value: 'no'}]
      field :dropdown2, type: :select, select_options: [['Yes','yes'],['No','no']]
      field :dropdown3, type: :select, select_options: ['yes','no']
      field :dropdown4, type: :select, select_options: [:yes,:no]
      field :dropdown5, type: :select, select_options: :options5
      field :dropdown6, type: :select, select_options: :options6
      field :dropdown7, type: :select, select_options: :options7
      field :dropdown8, type: :select, select_options: :options8
      def options5
        [{description: 'Yes', value: 'yes'}, {description: 'No', value: 'no'}]
      end
      def options6
        [['Yes','yes'],['No','no']]
      end
      def options7
        ['yes','no']
      end
      def options8
        [:yes,:no]
      end
    end

    class SuperHeroTeam::Member
      include PopulateMe::Document
    end

    def find_field fields, name
      fields.find{|f| f[:field_name]==name}
    end

    describe '#to_admin_url' do
        
      it 'Only puts the ID if there is one yet' do
        SuperHeroTeam::Member.new.to_admin_url.should=='super-hero-team--member'
        SuperHeroTeam::Member.new(id: 'x-men').to_admin_url.should=='super-hero-team--member/x-men'
      end

    end

    describe '#to_admin_list_item' do

      it 'Returns the relevant default info' do
        team = SuperHeroTeam.new id: 'x-men', name: 'X Men'
        info = team.to_admin_list_item
        [:class_name,:id,:admin_url,:title].all?{|i| info.keys.include?(i)}.should==true
      end

    end

    describe '::to_admin_list' do

      it 'Returns the relevant default info' do
        info = SuperHeroTeam.to_admin_list
        [:template,:page_title,:dasherized_class_name,:items].all?{|i| info.keys.include?(i)}.should==true
        info[:template].should=='template_list'
        info[:items].should==[]
        team = SuperHeroTeam.new id: 'x-men', name: 'X Men'
        team.save
        info = SuperHeroTeam.to_admin_list
        info[:items].include?(team.to_admin_list_item)
      end

    end

    describe '#to_admin_form' do

      it 'Returns the relevant default info' do
        team = SuperHeroTeam.new
        info = team.to_admin_form
        existing_team = SuperHeroTeam.admin_get('x-men')
        existing_team_info = existing_team.to_admin_form
        [:template,:page_title,:admin_url,:is_new,:fields].all?{|i| info.keys.include?(i)}.should==true
        info[:template].should=='template_form'
        info[:page_title].should=='New Super Hero Team'
        existing_team_info[:page_title].should=='X Men'
        info[:is_new].should==true
        existing_team_info[:is_new].should==false
        info[:fields].size.should>0
      end

      it 'Changes the template if the :nested option is used' do
        SuperHeroTeam.new.to_admin_form(nested: true)[:template].should=='template_nested_form'
      end

      it 'Adds the _class field' do
        team = SuperHeroTeam.new
        info = team.to_admin_form
        class_field = info[:fields][0]
        class_field[:field_name].should==:_class
        class_field[:type].should==:hidden
        class_field[:input_name].should=='data[_class]'
        class_field[:input_value].should=='SuperHeroTeam'
        class_field[:input_attributes][:type].should==:hidden
      end

      it 'Sets the :wrap option of form fields correctly' do
        fields = SuperHeroTeam.new.to_admin_form[:fields]
        find_field(fields,:_class)[:wrap].should==false
        find_field(fields,:members)[:wrap].should==false
        find_field(fields,:active)[:wrap].should==false
        find_field(fields,:name)[:wrap].should==true
      end

      it 'Does not include the fields with :form_field==false' do
        fields = SuperHeroTeam.new.to_admin_form[:fields]
        find_field(fields,:score).should==nil
      end

      it 'Can change the input name prefix for form fields' do
        fields = SuperHeroTeam.new.to_admin_form(input_name_prefix: 'data[bababa][]')[:fields]
        find_field(fields,:name)[:input_name].should=='data[bababa][][name]'
      end

      it 'Includes nested documents' do
        hero = SuperHeroTeam::Member.new
        hero_form = hero.to_admin_form(input_name_prefix: 'data[members][]')
        team = SuperHeroTeam.new
        team.members << hero
        fields = team.to_admin_form[:fields]
        find_field(fields,:members)[:items][0].should==hero_form
      end

      it 'Can build select_options from hash, array, or a method' do
        expected = [{description: 'Yes', value: 'yes'},{description: 'No', value: 'no', selected: true}]
        team = SuperHeroTeam.new
        (1..8).each{|n| team.__send__("dropdown#{n}=".to_sym,'no')}
        fields = team.to_admin_form[:fields]
        (1..8).each do |n|
          find_field(fields,"dropdown#{n}".to_sym)[:select_options].should==expected
        end
      end

    end

  end

end

