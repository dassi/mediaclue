class Document < Medium


  # Mime type of Office documents:
  # .xlsx   application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
  # .xltx   application/vnd.openxmlformats-officedocument.spreadsheetml.template
  # .potx   application/vnd.openxmlformats-officedocument.presentationml.template
  # .ppsx   application/vnd.openxmlformats-officedocument.presentationml.slideshow
  # .pptx   application/vnd.openxmlformats-officedocument.presentationml.presentation
  # .sldx   application/vnd.openxmlformats-officedocument.presentationml.slide
  # .docx   application/vnd.openxmlformats-officedocument.wordprocessingml.document
  # .dotx   application/vnd.openxmlformats-officedocument.wordprocessingml.template
  # .xlam   application/vnd.ms-excel.addin.macroEnabled.12
  # .xlsb   application/vnd.ms-excel.sheet.binary.macroEnabled.12

  CONTENT_TYPES = ['application/pdf',
                   'application/msword',
                   'application/vnd.ms-excel',
                   'application/vnd.ms-powerpoint',
                   'application/zip',
                   # 'application/x-zip',
                   'application/vnd.oasis.opendocument.text',         # OpenOffice Text-Dokument
                   'application/vnd.oasis.opendocument.spreadsheet',  # OpenOffice Tabellen-Dokument
                   'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',           # Excel XML
                   'application/vnd.openxmlformats-officedocument.presentationml.slideshow',      # PowerPoint XML
                   'application/vnd.openxmlformats-officedocument.presentationml.presentation',   # PowerPoint XML
                   'application/vnd.openxmlformats-officedocument.wordprocessingml.document',     # Word XML
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
