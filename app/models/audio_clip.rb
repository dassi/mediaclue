class AudioClip < Medium
  CONTENT_TYPES = ['audio/mpeg', 'audio/mp4', 'audio/x-wav']

  def self.type_display_name
    "Audio Clip"
  end
  
  def self.type_display_name_plural
    "Audio Clips"
  end
  
  # Liefert weitere erlaubte Dateiendungen. 
  def self.additional_file_extensions
    # M4A wird von der MIME-Library nicht richtig erkannt
    {'audio/mp4' => ['m4a']}
  end
    

end
