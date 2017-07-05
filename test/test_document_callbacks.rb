require 'helper'
require 'populate_me/document'

class Hamburger < PopulateMe::Document
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

describe PopulateMe::Document, 'Callbacks' do

  parallelize_me!

  let(:subject_class) { Hamburger }
  subject { subject_class.new taste: 'good' }
  let(:layers_callbacks) { subject_class.callbacks[:layers] }

  it 'Registers callbacks as symbols or blocks' do
    assert_equal 3, layers_callbacks.size
    assert_equal :bread, layers_callbacks[0]
    assert_equal :cheese, layers_callbacks[1]
    assert_equal 'good', subject.instance_eval(&layers_callbacks[2])
  end

  it 'Executes symbol or block callbacks' do
    subject.exec_callback('after_cook')
    assert_equal 'good with salad with more cheese', subject.taste
  end

  it 'Does not raise if executing a callback which does not exist' do
    subject.exec_callback(:after_burn)
    assert_equal 'good', subject.taste
  end

  it 'Has an option to prepend when registering callbacks' do
    subject.exec_callback(:after_eat)
    assert_equal 'good for my stomach', subject.taste
  end

  it 'Has callbacks shortcut for before_ prefix' do
    subject.exec_callback(:before_digest)
    assert_equal 'good was the taste.', subject.taste
  end
  it 'Has callbacks shortcut for after_ prefix' do
    subject.exec_callback(:after_digest)
    assert_equal 'good was the taste.', subject.taste
  end

  it 'Can pass the callback name as an argument to the callback method' do
    subject.exec_callback(:before_argument)
    assert_equal 'good before_argument', subject.taste
    subject.exec_callback(:after_argument)
    assert_equal 'good before_argument after_argument', subject.taste
  end

  describe '#ensure_position' do

    class RaceCar < PopulateMe::Document
      field :name
      field :team
      field :position_by_team, type: :position, scope: :team 
      position_field
    end

    before do
      RaceCar.documents = []
    end

    it 'Does not change position if already set' do
      RaceCar.new(name: 'racer3', position: 3, team: 'A', position_by_team: 14).save
      car = RaceCar.new(name: 'racer1', position: 12, team: 'A', position_by_team: 41)
      car.ensure_position
      assert_equal 12, car.position
      assert_equal 41, car.position_by_team
    end

    it 'Sets position fields to last position' do
      RaceCar.new(name: 'racer1', position: 1, team: 'A', position_by_team: 41).save
      RaceCar.new(name: 'racer2', position: 2, team: 'B', position_by_team: 12).save
      RaceCar.new(name: 'racer3', position: 3, team: 'B', position_by_team: 14).save
      car = RaceCar.new(team: 'B').ensure_position
      assert_equal 4, car.position
      assert_equal 15, car.position_by_team
    end

    it 'Returns 0 when first document in scope' do
      assert_equal 0, RaceCar.new.ensure_position.position
      RaceCar.new(name: 'racer1', position: 1, team: 'A', position_by_team: 41).save
      assert_equal 0, RaceCar.new(team: 'B').ensure_position.position_by_team
    end

    it "Ensures position before creating new document" do
      car = RaceCar.new
      car.save
      assert_equal 0, car.position
    end

  end

end

