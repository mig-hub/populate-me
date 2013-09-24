# encoding: utf-8
Encoding.default_internal = Encoding.default_external = Encoding::UTF_8 if RUBY_VERSION >= '1.9.0'

require 'rubygems'
require 'bacon'
$:.unshift './lib'
require "populate_me/ext"

describe 'Integer' do
  describe '#to_price_string' do
    should 'Display numbers correctly' do
      4595.to_price_string.should=='45.95'
      7000.to_price_string.should=='70'
      1234567890.to_price_string.should=='12,345,678.90'
      -140000.to_price_string.should=='-1,400'
    end
  end
end

describe 'String' do
  describe '#to_price_integer' do
    should 'Parse numbers correctly' do
      '28'.to_price_integer.should==2800
      '45.95'.to_price_integer.should==4595
      '   £-12,345,678.90   '.to_price_integer.should==-1234567890
    end
  end
end
