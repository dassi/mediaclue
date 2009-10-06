class Image < Medium  
  CONTENT_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/tiff']  
  
  has_attachment :content_type => CONTENT_TYPES,
                 :storage => :file_system,
                 :path_prefix => MEDIA_STORAGE_PATH_PREFIX,
                 # Warum fix beschränken? Speicherplatz ist billig und Bild-Qualität ist entscheidend
                 # OPTIMIZE: In eine System-Einstellung auslagern
                 :max_size => [100.megabytes, MAX_FILE_SIZE].compact.min,
                 # :resize_to => '3000x3000>',
                 :thumbnail_class => 'ImageThumbnail',
                 :thumbnails => { :thumbnail => '85x85>',
                                  :small => '150x150>',
                                  :medium => '350x350>',
                                  :big => '800x800>',
                                  :pdfslideshow => '1400x1400>'
                                }

	validates_as_attachment
	

  protected #######################################################################################

  
  public ##########################################################################################
  
  # Fake für attachment_fu (Blödes Ding!). An manchen Orten im Code prüft attachment_fu auf das Vorhandensein von parent_id.
  # Und: Methode aus attachment_fu überschreiben, weil die nicht zuverlässig arbeiten, mit Verwendung von thumbnail_class-Option
  # und zwei getrennten DB-Tabellen
  attr_accessor :parent_id
  def thumbnailable?
    true
  end
  
  def dimensions        
    "#{width}x#{height}"
  end
  
  def self.type_display_name
    "Bild"
  end

  def tiff?
    content_type == 'image/tiff'
  end

  def jpeg?
    content_type == 'image/jpeg'
  end
                               
  def png?
    content_type == 'image/png'
  end
                               
  def gif?
    content_type == 'image/gif'
  end
                               

end
