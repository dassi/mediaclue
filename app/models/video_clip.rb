class VideoClip < Medium
  CONTENT_TYPES = ['video/quicktime', 'video/x-flv', 'video/mpeg']

  has_attachment :content_type => CONTENT_TYPES,
                 :storage => :file_system,
                 :path_prefix => MEDIA_STORAGE_PATH_PREFIX
                 # :max_size => 200.megabytes

  validates_as_attachment
 
  def type_display_name
    "Video Clip"
  end
  
end
