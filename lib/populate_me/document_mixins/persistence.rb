module PopulateMe
  module DocumentMixins
    module Persistence

      def persistent_instance_variables
        instance_variables.select do |k|
          if self.class.fields.empty?
            k !~ /^@_/
          else
            self.class.fields.key? k[1..-1].to_sym
          end
        end
      end

      def attachment f
        attacher = Utils.resolve_class_name self.class.fields[f][:class_name]
        attacher.new self, f
      end

      # Saving
      def save
        return unless valid?
        exec_callback :before_save
        if new?
          exec_callback :before_create
          id = perform_create
          exec_callback :after_create
        else
          exec_callback :before_update
          id = perform_update
          exec_callback :after_update
        end
        exec_callback :after_save
        id
      end
      def perform_create
        self.class.documents << self.to_h
        self.id
      end
      def perform_update
        index = self.class.documents.index{|d| d['id']==self.id }
        raise MissingDocumentError, "No document can be found with this ID: #{self.id}" if self.id.nil?||index.nil?
        self.class.documents[index] = self.to_h
      end

      # Deletion
      def delete o={}
        exec_callback :before_delete
        perform_delete
        exec_callback :after_delete
      end
      def perform_delete
        index = self.class.documents.index{|d| d['id']==self.id }
        raise MissingDocumentError, "No document can be found with this ID: #{self.id}" if self.id.nil?||index.nil?
        self.class.documents.delete_at(index)
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        attr_writer :documents

        def documents; @documents ||= []; end

        def id_string_key
          (self.fields.keys[0]||'id').to_s
        end

        def set_indexes f, ids=[]
          ids.each_with_index do |id,i|
            self.documents.each do |d|
              d[f.to_s] = i if d[self.id_string_key]==id
            end
          end
          self
        end

      end

    end
  end
end

