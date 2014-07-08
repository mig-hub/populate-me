module PopulateMe
  class Builder
    attr_accessor :to_s

    def self.create(&block); self.new(false,&block).to_s; end
    def self.create_here(&block); self.new(true,&block).to_s; end

    def initialize outer_scope=false, &block
      @to_s = ""
      return self unless block_given?
      unless outer_scope
        instance_eval(&block)
      else
        block.call(self)
      end
      self
    end

    def method_missing(meth, args={}, &block); tag(meth, args, &block); end

    def tag name, attributes={}
      @to_s << "<#{name}"
      if attributes.kind_of?(String)
        @to_s << ' ' << attributes
      else
        @to_s << attributes.delete_if{|k,v| v.nil? or v==false }.map{|(k,v)| " #{k}='#{_fragment_escape_entities(v)}'" }.join
      end
      if block_given?
        @to_s << ">"
        text = yield
        @to_s << text.to_str if text != @to_s and text.respond_to?(:to_str)
        @to_s << "</#{name}>"
      else
        @to_s << ' />'
      end
    end

    def _fragment_escape_entities(s)
      s.to_s.gsub(/&/, '&amp;').gsub(/"/, '&quot;').gsub(/'/, '&apos;').gsub(/</, '&lt;').gsub(/>/, '&gt;')
    end
    
    # Override Kernel methods
    
    def p(args={}, &block); tag(:p, args, &block); end
    def select(args={}, &block); tag(:select, args, &block); end
    
    # Basic helpers

    def write(s=''); @to_s << s; end
    def doctype; write "<!DOCTYPE html>\n"; end
    def comment(s=''); write "\n<!-- #{s} -->\n"; end
  end
end

