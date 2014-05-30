require 'bacon'
$:.unshift File.expand_path('../../lib', __FILE__)
require 'populate_me/document'

class User
  include PopulateMe::Document
  def validate
    super
    error_on('prohibited','Is not allowed') unless self['prohibited'].nil?
    error_on('prohibited','Is not good') unless self['prohibited'].nil?
  end
  def before_create
    super
  end
  def before_save
    super
    self['numbers'] ||= [1,2,3]
    self['fullname'] = "Mr #{self['fullname']}" unless self['fullname'][/Mr /]
  end
end

describe 'PopulateMe::Document' do
  it 'Interfaces with the underlying hash' do
    User.new.to_h.should=={}
    User.new({'num'=>42}).to_h['num'].should==42
    u = User.new({'num'=>42,'meta'=>{'cat'=>'siamese'}})
    u['num'].should==42
    u['meta']['cat'].should=='siamese'
    u['meta'] = nil
    u['meta'].should==nil
  end
  it 'Handles validations' do
    u = User.new
    u.errors.should=={}
    u.valid?.should==true
    u['prohibited'] = 'I dare'
    u.valid?.should==false
    u.errors['prohibited'].should==['Is not allowed','Is not good']
    u.to_h.delete('prohibited')
    u.valid?.should==true
  end
  it 'Saves correctly' do
    User.api_get_all.should==[]
    inst = User.api_post({
      'fullname'=>'Bobby',
      'meta'=>{'cat'=>'siamese'},
      'numbers'=>[1,2,3]
    })
    inst['fullname'].should=='Bobby'
    inst['meta']['cat'].should=='siamese'
    inst['numbers'].should==[1,2,3]
    inst['id'].should!=nil
    User.api_get_all.size.should>0
    inst.to_h.should==User.api_get_all[0]
    inst2 = User.api_post
    inst2['id'].should!=nil
    inst2['id'].should!=inst['id']
  end

  # it 'Deletes correctly' do

  # end
end

