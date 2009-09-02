class Image < Medium  
  CONTENT_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/tiff']  
  
  has_attachment :content_type => CONTENT_TYPES,
                 :storage => :file_system,
                 :path_prefix => MEDIA_STORAGE_PATH_PREFIX,
                 :max_size => 10.megabytes,
                 :resize_to => '3000x3000>',
                 :thumbnails => { :thumbnail => '85x85>',
                                  :small => '150x150>',
                                  :medium => '350x350>',
                                  :big => '800x800>',
                                  :pdfslideshow => '1400x1400>'
                                }

	validates_as_attachment
  
  def dimensions        
    "#{width}x#{height}"
  end
  
  def type_display_name
    "Bild"
  end

end
