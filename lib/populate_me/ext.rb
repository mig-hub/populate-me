# encoding: utf-8

# Extends standard classes

Integer.class_eval do
  def to_price_string
    ("%.2f" % (self/100.0)).sub(/\.00/, '')
  end
end

String.class_eval do
  def to_price_integer
    ("%.2f" % self.gsub(/[^\d\.\-]/, '')).gsub(/\./,'').to_i
  end
end

