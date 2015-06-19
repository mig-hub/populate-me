require 'populate_me/utils'
require 'ostruct'

require 'populate_me/document_mixins/typecasting'
require 'populate_me/document_mixins/outcasting'
require 'populate_me/document_mixins/schema'
require 'populate_me/document_mixins/admin_adapter'
require 'populate_me/document_mixins/callbacks'
require 'populate_me/document_mixins/validation'
require 'populate_me/document_mixins/persistence'

module PopulateMe

  class MissingDocumentError < StandardError; end
  class MissingAttachmentClassError < StandardError; end

  class Document

    # PopulateMe::Document is the base for any document
    # the Backend is supposed to deal with.
    #
    # Any module for a specific ORM or ODM should
    # subclass it.
    # It contains what is not specific to a particular kind
    # of database and it provides defaults.
    #
    # It can be used on its own but it keeps everything
    # in memory. Which means it is only for tests and conceptual
    # understanding.
    
    include DocumentMixins::Typecasting
    include DocumentMixins::Outcasting
    include DocumentMixins::Schema
    include DocumentMixins::AdminAdapter
    include DocumentMixins::Callbacks
    include DocumentMixins::Validation
    include DocumentMixins::Persistence

    class << self

      def inherited sub 
        super
        sub.callbacks = Utils.deep_copy callbacks
        sub.settings = settings.dup # no deep copy because of Mongo.settings.db
      end

      def to_s
        super.gsub(/[A-Z]/, ' \&')[1..-1].gsub('::','')
      end

      def to_s_short
        self.name[/[^:]+$/].gsub(/[A-Z]/, ' \&')[1..-1]
      end

      def to_s_plural; Utils.pluralize(self.to_s); end
      def to_s_short_plural; Utils.pluralize(self.to_s_short); end

      def from_hash hash, o={}
        old = self.new(_is_new: false).set_from_hash hash, o
        self.new(_is_new: false, _old: old).set_from_hash hash, o
      end

      # inheritable settings
      attr_accessor :settings
      def set name, value
        self.settings[name] = value
      end

    end

    attr_accessor :id, :_is_new, :_old

    def initialize attributes=nil 
      self._is_new = true
      set attributes if attributes
      self._errors = {}
    end

    def inspect
      "#<#{self.class.name}:#{to_h.inspect}>"
    end

    def to_s
      return inspect if self.class.label_field.nil?
      me = self.__send__(self.class.label_field)
      Utils.blank?(me) ? inspect : me
    end

    def new?; self._is_new; end

    def to_h
      persistent_instance_variables.inject({'_class'=>self.class.name}) do |h,var|
        k = var.to_s[1..-1]
        v = instance_variable_get var
        if v.is_a? Array
          h[k] = v.map(&:to_h)
        else
          h[k] = v
        end
        h
      end
    end
    alias_method :to_hash, :to_h

    def nested_docs
      persistent_instance_variables.map do |var|
        instance_variable_get var
      end.find_all do |val|
        val.is_a? Array
      end.flatten
    end

    def == other
      return false unless other.respond_to?(:to_h)
      other.to_h==to_h
    end

    def set attributes
      attributes.dup.each do |k,v| 
        setter = "#{k}="
        if respond_to? setter
          __send__ setter, v
        else
          puts "! #{self.class} has no field called #{k}" unless ENV['RACK_ENV']=='test'
        end
      end
      self
    end

    def set_defaults o={}
      self.class.fields.each do |k,v|
        if v.key?(:default)&&(__send__(k).nil?||o[:force])
          set k.to_sym => Utils.get_value(v[:default],self)
        end
      end
      self
    end

    def set_from_hash hash, o={}
      raise(TypeError, "#{hash} is not a Hash") unless hash.is_a? Hash
      hash = hash.dup # Leave original untouched
      hash.delete('_class')
      hash.each do |k,v|
        if v.is_a? Array
          __send__(k.to_sym).clear
          v.each do |d|
            obj =  Utils.resolve_class_name(d['_class']).new.set_from_hash(d,o)
            __send__(k.to_sym) << obj
          end
        else
          v = typecast(k.to_sym,v) if o[:typecast]
          set k.to_sym => v
        end
      end
      self
    end

    # class settings
    def settings
      self.class.settings
    end
    self.settings = OpenStruct.new

  end
end

