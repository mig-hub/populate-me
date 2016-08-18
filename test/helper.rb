ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'

module Minitest::Assertions
  def assert_json response
    assert response.content_type=="application/json", "Expected #{response.inspect} to be a JSON response"
  end
  def assert_for_view json, view_name, title=nil
    assert json['template']==view_name, "Expected #{json.inspect} to have 'template' set to '#{view_name}'"
    unless title.nil?
      assert json['page_title']==title, "Expected #{json.inspect} to have 'page_title' set to '#{title}'"
    end
  end

  def assert_receive obj, meth, retval=nil, args=[] 
    mocked_meth = Minitest::Mock.new
    mocked_meth.expect(:call, retval, args)
    obj.stub meth, mocked_meth do
      yield
    end
    assert mocked_meth.verify, "Expected #{obj.inspect} to receive :#{meth}"
  end
  def refute_receive obj, meth
    proof = nil
    obj.stub meth, proc{proof = :received} do
      yield
      assert(proof!=:received, "Expected #{obj.inspect} not to receive :#{meth}")
    end
  end
end

module Minitest::Expectations
  infect_an_assertion :assert_json, :must_be_json, :unary
  infect_an_assertion :assert_for_view, :must_be_for_view, :reverse
end

class Minitest::Spec
  include Rack::Test::Methods
end

