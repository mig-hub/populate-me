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

end

