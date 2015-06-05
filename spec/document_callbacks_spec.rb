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

RSpec.describe PopulateMe::Document, 'Callbacks' do

  let(:subject_class) { Hamburger }
  subject { subject_class.new taste: 'good' }
  let(:layers_callbacks) { subject_class.callbacks[:layers] }

  it 'Registers callbacks as symbols or blocks' do
    expect(layers_callbacks.size).to eq 3
    expect(layers_callbacks[0]).to eq :bread
    expect(layers_callbacks[1]).to eq :cheese
    expect(subject.instance_eval(&layers_callbacks[2])).to eq 'good'
  end

  it 'Executes symbol or block callbacks' do
    subject.exec_callback('after_cook')
    expect(subject.taste).to eq 'good with salad with more cheese'
  end

  it 'Does not raise if executing a callback which does not exist' do
    subject.exec_callback(:after_burn)
    expect(subject.taste).to eq 'good'
  end

  it 'Has an option to prepend when registering callbacks' do
    subject.exec_callback(:after_eat)
    expect(subject.taste).to eq 'good for my stomach'
  end

  it 'Has callbacks shortcut for before_ prefix' do
    subject.exec_callback(:before_digest)
    expect(subject.taste).to eq 'good was the taste.'
  end
  it 'Has callbacks shortcut for after_ prefix' do
    subject.exec_callback(:after_digest)
    expect(subject.taste).to eq 'good was the taste.'
  end

  it 'Can pass the callback name as an argument to the callback method' do
    subject.exec_callback(:before_argument)
    expect(subject.taste).to eq 'good before_argument'
    subject.exec_callback(:after_argument)
    expect(subject.taste).to eq 'good before_argument after_argument'
  end

end

