class AudioClip < Medium
  CONTENT_TYPES = ['audio/mpeg', 'audio/mp4', 'audio/x-wav']

  has_attachment :content_type => CONTENT_TYPES,
                 :storage => :file_system,
                 :path_prefix => MEDIA_STORAGE_PATH_PREFIX,
                 :max_size => [100.megabytes, MAX_FILE_SIZE].compact.min

  validates_as_attachment
 
  def self.type_display_name
    "Audio Clip"
  end
  
  # Liefert weitere erlaubte Dateiendungen. 
  def self.additional_file_extensions
    # M4A wird von der MIME-Library nicht richtig erkannt
    {'audio/mp4' => ['m4a']}
  end
    

end
