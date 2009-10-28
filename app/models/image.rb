class Image < Medium  

  CONTENT_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/tiff']  
  
  protected #######################################################################################
  
  public ##########################################################################################

  def self.with_image(file, &block)
    ::ImageScience.with_image file, &block
  end
  
  def dimensions        
    "#{width}x#{height}"
  end
  
  def self.type_display_name
    "Bild"
  end

  def self.type_display_name_plural
    "Bilder"
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

  def process_attachment
    super

    # return unless @saved_attachment
    
    with_image do |img|
      self.width  = img.width  if respond_to?(:width)
      self.height = img.height if respond_to?(:height)
      resize_image_or_thumbnail! img
    end
  end

  # Resizes the given processed img object with either the attachment resize options or the thumbnail resize options.
  def resize_image_or_thumbnail!(img)
    # if attachment_options[:resize_to] # parent image
      # resize_image(img, '3000x3000>')
    # end
  end

  # Performs the actual resizing operation for a thumbnail
  def resize_image(img, size)
    # create a dummy temp file to write to
    # ImageScience doesn't handle all gifs properly, so it converts them to
    # pngs for thumbnails.  It has something to do with trying to save gifs
    # with a larger palette than 256 colors, which is all the gif format
    # supports.
    # filename.sub!(/gif$/, 'png')
    # content_type.sub!(/gif$/, 'png')
    # 
    # # Andreas Brodbeck (mindclue):
    # # TIFFs in JPEGs verwandeln
    # filename.sub!(/tiff$/, 'jpg')
    # filename.sub!(/tif$/, 'jpg')
    # content_type.sub!(/tiff$/, 'jpeg')
    
    temp_paths.unshift write_to_temp_file(filename)
    grab_dimensions = lambda do |img|
      self.width  = img.width  if respond_to?(:width)
      self.height = img.height if respond_to?(:height)
      img.save self.temp_path
      self.size = File.size(self.temp_path)
    end

    img.resize(size[0], size[1], &grab_dimensions)
  end
  
  def with_image(&block)
    self.class.with_image(temp_path, &block)
  end
                               


end
