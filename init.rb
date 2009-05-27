# Include hook code here
require 'attachment_fu_cache'
ActiveRecord::Base.send :extend, AttachmentCacheHasOne
ActiveRecord::Base.send :extend, AttachmentCacheBelongsTo
