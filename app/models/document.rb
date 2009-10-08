class Document < Medium
  CONTENT_TYPES = ['application/pdf', 'application/msword', 'application/vnd.ms-excel', 'application/vnd.ms-powerpoint', 'application/zip']
  
  has_attachment :content_type => CONTENT_TYPES,
                 :storage => :file_system,
                 :path_prefix => MEDIA_STORAGE_PATH_PREFIX,
                 :max_size => [500.megabytes, MAX_FILE_SIZE].compact.min
               
  validates_as_attachment

  def self.type_display_name
    "Dokument"
  end
               
  def self.type_display_name_plural
    "Dokumente"
  end
               
end
