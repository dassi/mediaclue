class VideoClip < Medium

  CONTENT_TYPES = ['video/quicktime', 'video/x-flv', 'video/mpeg', 'video/mp4', 'video/x-m4v']

  def self.type_display_name
    "Video Clip"
  end
  
  def self.type_display_name_plural
    "Video Clips"
  end
  
end
