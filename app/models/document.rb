class Document < Medium
  CONTENT_TYPES = ['application/pdf', 'application/msword', 'application/vnd.ms-excel', 'application/vnd.ms-powerpoint', 'application/zip']
  
  has_attachment :content_type => CONTENT_TYPES,
                 :storage => :file_system,
                 :path_prefix => MEDIA_STORAGE_PATH_PREFIX,
                 :max_size => 500.megabytes
               
  validates_as_attachment

  def type_display_name
    "Dokument"
  end
               
end
