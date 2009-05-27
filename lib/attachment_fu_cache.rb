module AttachmentCacheMethods
  def picture_exist?
    # check cached columns only
    !cached_public_filename.blank?
  end

  def public_filename(thumbnail = nil)
    return cached_public_filename if thumbnail.blank?

    ext = nil
    basename = cached_public_filename.gsub /\.\w+$/ do |s|
      ext = s; ''
    end
    #"#{basename}_#{thumbnail}#{ext}"
    File.dirname(basename) + '/' + sanitize_filename("#{basename}_#{thumbnail}#{ext}")
  end
  
  # Downcase and remove extra underscores from uploaded images
  def sanitize_filename(filename)
    returning filename.strip do |name|
      # NOTE: File.basename doesn't work right with Windows paths on Unix
      # get only the filename, not the whole path
      name.gsub! /^.*(\\|\/)/, ''
    
      # Finally, replace all non alphanumeric, underscore or periods with underscore
      name.gsub! /[^\w\.\-]/, '_'
    
      # Remove multiple underscores
      name.gsub!(/\_+/, '_')
  
      # Downcase result including extension
      # This seems to be causing some problems with mixed case filenames.
      # name.downcase!
      
    end
  end
end

module AttachmentCacheHasOne
  def has_one_attachment_cache(assocation_id, opts = {})
    include AttachmentCacheMethods

    has_one assocation_id, opts
  end

end


module AttachmentCacheBelongsTo
  def belongs_to_attachment_cache(assocation_id, opts = {})
    belongs_to assocation_id, opts
    class_name = opts[:class_name] || assocation_id.to_s.classify
    table_name = class_name.tableize
    # puts "%" * 30 + " assocation_id: #{assocation_id.inspect}"
    # puts "%" * 30 + " class_name: #{class_name.inspect}"
    # puts "%" * 30 + " table_name: #{table_name.inspect}"

    # slower
    #{class_name}.update_all ["cached_public_filename = ?", public_filename], ["id = ?", #{assocation_id}.id]

    class_eval <<-CODE
      after_save :save_attachment_cache
      def save_attachment_cache
        if #{assocation_id}
#          puts "%" * 30 + "update all called1"
#          puts #{assocation_id}.id
#          puts #{class_name}.id
#          puts "%" * 30 + "update all called2"
          
          # slower, but works with the cropper
          #{assocation_id}.update_attribute(:cached_public_filename, public_filename)
          
#          # faster, doesnt update the object with th cropper?
#          #{class_name}.update_all ["cached_public_filename = ?", public_filename], ["id = ?", #{assocation_id}.id]
          
          puts %{#{class_name}.update_all ["cached_public_filename = ?", public_filename], ["id = ?", #{assocation_id}.id]}
        end
      end
    CODE

    class_eval <<-CODE
      after_destroy :destroy_attachment_cache
      def destroy_attachment_cache
        if #{assocation_id}
          #{class_name}.update_all ["cached_public_filename = NULL"], ["id = ?", #{assocation_id}.id]
        end
      end
    CODE
  end
end
