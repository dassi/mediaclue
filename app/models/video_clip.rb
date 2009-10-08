class VideoClip < Medium
  CONTENT_TYPES = ['video/quicktime', 'video/x-flv', 'video/mpeg', 'video/mp4']

  has_attachment :content_type => CONTENT_TYPES,
                 :storage => :file_system,
                 :path_prefix => MEDIA_STORAGE_PATH_PREFIX,
                 :max_size => [1000.megabytes, MAX_FILE_SIZE].compact.min

  validates_as_attachment
 
  def self.type_display_name
    "Video Clip"
  end
  
  def self.type_display_name_plural
    "Video Clips"
  end
  
end
