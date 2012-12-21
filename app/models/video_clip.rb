class VideoClip < Medium

  # Remarks: video/vnd.objectvideo = .m4v
  CONTENT_TYPES = ['video/quicktime', 'video/x-flv', 'video/mpeg', 'video/mp4', 'video/vnd.objectvideo']

  def self.type_display_name
    "Video Clip"
  end
  
  def self.type_display_name_plural
    "Video Clips"
  end
  
end
