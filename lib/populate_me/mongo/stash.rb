module PopulateMe
  module Mongo
    module Stash
  
      # This module gives models the ability to deal with attachments
  
    	def self.included(base)
    	  Stash.classes << base
    	  base.extend(ClassMethods)
    		base.gridfs = GRID
    	end

      module ClassMethods
    	  attr_accessor :gridfs
    	end
	
    	# Instance Methods
	
    	def build_image_tag(col='image', style='original', html_attributes={})
    	  return '' if @doc[col].nil?||@doc[col][style].nil?
    	  title_field, alt_field = col+'_tooltip', col+'_alternative_text'
    		title = @doc[title_field] if model.schema.keys.include?(title_field)
    		alt = @doc[alt_field] if model.schema.keys.include?(alt_field)
    		html_attributes = {:src => "/gridfs/#{@doc[col][style]}", :title => title, :alt => alt}.update(html_attributes)
    		html_attributes = html_attributes.map do |k,v|
    		  %{#{k}="#{model.html_escape(v.to_s)}"}
    		end.join(' ')
    	  "<img #{html_attributes} />"
    	end

    	def fix_type_attachment(k,v)
    	  if v=='nil'
          delete_files_for(k) unless new?
    			@doc[k] = nil
    	  elsif v.is_a?(Hash)&&v.key?(:tempfile)
    		  delete_files_for(k) unless new?
    			@temp_attachments ||= {}
    			@temp_attachments[k] = v
          attachment_id = model.gridfs.put(v[:tempfile], {:filename=>v[:filename], :content_type=>v[:type]})
    			@doc[k] = {'original'=>attachment_id}
    		end
    	end

    	def delete_files_for(col)
    	  obj = (@old_doc||@doc)[col]
    		if obj.respond_to?(:each)
    		  obj.each do |k,v|
    			  model.gridfs.delete(v)
    			end
    		end
    	end

    	def after_delete
    	  super
        model.schema.each do |k,v|
    		  delete_files_for(k) if v[:type]==:attachment
    		end
    	end

    	def after_save
    	  super
    		unless @temp_attachments.nil?
    			@temp_attachments.each do |k,v|
    				after_stash(k)
    			end
    		end
    	end

    	def after_stash(col); end

    	def convert(col, convert_steps, style)
    	  return if @doc[col].nil?
    	  if @temp_attachments.nil? || @temp_attachments[col].nil?
    	    f = model.gridfs.get(@doc[col]['original']) rescue nil
    	    return if f.nil?
    	    return unless f.content_type[/^image\//]
    	    src = Tempfile.new('MongoStash_src')
    	    src.binmode
    	    src.write(f.read(4096)) until f.eof?
    	    src.close
    	    @temp_attachments ||= {}
    	    @temp_attachments[col] ||= {}
    	    @temp_attachments[col][:tempfile] = src
    	    @temp_attachments[col][:type] = f.content_type
    		else
    		  return unless @temp_attachments[col][:type][/^image\//]
    		  src = @temp_attachments[col][:tempfile]
    		end
    	  model.gridfs.delete(@doc[col][style]) unless @doc[col][style].nil?
    		ext = style[/[a-zA-Z]+$/].insert(0,'.')
    		dest = Tempfile.new(['MongoStash_dest', ext])
    		dest.binmode
    		dest.close
    	  system "convert \"#{src.path}\" #{convert_steps} \"#{dest.path}\""
    		filename = "#{model.name}/#{self.id}/#{style}"
    		content_type = Rack::Mime.mime_type(ext) 
    		attachment_id = model.gridfs.put(dest.open, {:filename=>filename, :content_type=>content_type})
        @doc[col] = @doc[col].update({style=>attachment_id})
    		model.collection.update({'_id'=>@doc['_id']}, @doc)
    		#src.close!
    		dest.close!
    	end

    	class << self
    	  attr_accessor :classes
    		Stash.classes = []
    		
    		def all_after_stash
    		  Stash.classes.each do |m|
    			  m.collection.find.each do |i|
    				  m.schema.each do |k,v|
    					  m.new(i).after_stash(k) if v[:type]==:attachment
    					end
    				end
    			end
    		end
    		
    		def fix_dots_in_keys(c, for_real=false)
          puts "\n#{c}" unless for_real
          img_keys = c.schema.select{|k,v| v[:type]==:attachment }.keys
          c.find({}, {:fields=>img_keys}).each do |e|
            old_hash = e.doc.select{|k,v| img_keys.include?(k) }
            fixed_hash = Marshal.load(Marshal.dump(old_hash))
            img_keys.each do |k|
              (fixed_hash[k]||{}).keys.each do |style|
                fixed_hash[k][style.tr('.','_')] = fixed_hash[k].delete(style)
              end
            end
            next if old_hash==fixed_hash

            if for_real
              c.collection.update({'_id'=>e.id}, {'$set'=>fixed_hash})
            else
              puts old_hash.inspect
              puts fixed_hash.inspect
            end

          end
        end
        
        def all_fix_dots_in_keys(for_real=false)
          Stash.classes.each do |c|
            Stash.fix_dots_in_keys(c, for_real)
          end
        end

    	end

    end
  end
end
