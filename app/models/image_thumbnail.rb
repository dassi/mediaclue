class ImageThumbnail < ActiveRecord::Base

  has_attachment :storage => :file_system,
                 :path_prefix => MEDIA_STORAGE_PATH_PREFIX + 'thumbnails/'
                 
  # validates_as_attachment
  
end
