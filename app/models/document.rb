class Document < Medium
  CONTENT_TYPES = ['application/pdf',
                   'application/msword',
                   'application/vnd.ms-excel',
                   'application/vnd.ms-powerpoint',
                   'application/zip',                               
                   # 'application/x-zip',
                   'application/vnd.oasis.opendocument.text',         # OpenOffice Text-Dokument
                   'application/vnd.oasis.opendocument.spreadsheet',  # OpenOffice Tabellen-Dokument
                   'application/x-shockwave-flash']
  
  def self.type_display_name
    "Dokument"
  end
               
  def self.type_display_name_plural
    "Dokumente"
  end
  
  def powerpoint?
    content_type == 'application/vnd.ms-powerpoint'
  end
  
  def word?
    content_type == 'application/msword'
  end
  
  def pdf?
    content_type == 'application/pdf'
  end
  
  def excel?
    content_type == 'application/vnd.ms-powerpoint'
  end
  
  def zip?
    content_type == 'application/zip'
  end
  
               
end
