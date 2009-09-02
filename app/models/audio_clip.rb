class AudioClip < Medium
  CONTENT_TYPES = ['audio/mpeg', 'audio/mp4', 'audio/x-wav']

  has_attachment :content_type => CONTENT_TYPES,
                 :storage => :file_system,
                 :path_prefix => MEDIA_STORAGE_PATH_PREFIX,
                 :max_size => 10.megabytes

  validates_as_attachment
 
  def type_display_name
    "Audio Clip"
  end

end
