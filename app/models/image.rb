require 'uri'

class Image < Medium  

  CONTENT_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/tiff']  
  
  protected #######################################################################################

  def preprocess_meta_data(exif_data_hash)
    # nichts tun
  end
  
  public ##########################################################################################

  def self.with_image(file, &block)
    ::ImageScience.with_image(file, &block)
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

    with_image do |img|
      self.width  = img.width
      self.height = img.height
      # resize_image_or_thumbnail! img
    end
    
    true
  end

  # Resizes the given processed img object with either the attachment resize options or the thumbnail resize options.
  def resize_image_or_thumbnail!(img)
    # if attachment_options[:resize_to] # parent image
      # resize_image(img, '3000x3000>')
    # end
  end

  # # Performs the actual resizing operation for a thumbnail
  # def resize_image(img, size)
  #   self.temp_path = write_to_temp_file(filename)
  #   grab_dimensions = lambda do |img|
  #     self.width  = img.width  if respond_to?(:width)
  #     self.height = img.height if respond_to?(:height)
  #     img.save self.temp_path
  #     self.size = File.size(self.temp_path)
  #   end
  # 
  #   img.resize(size[0], size[1], &grab_dimensions)
  # end
  
  def with_image(&block)
    self.class.with_image(self.temp_path, &block)
  end

  def has_geo_information
    self.meta_data.present? && (not ((longitude && latitude) || altitude).nil?)
  end
  
  def longitude
    self.meta_data && self.meta_data['GPSLongitude'] && self.meta_data['GPSLongitude'].gsub(' deg', '°')
  end

  def latitude
    self.meta_data && self.meta_data['GPSLatitude'] && self.meta_data['GPSLatitude'].gsub(' deg', '°')
  end
  
  def altitude
    self.meta_data && self.meta_data['GPSAltitude']
  end
  
  def url_to_google_maps
    URI::escape("http://maps.google.ch/maps?q=#{self.latitude},#{self.longitude}")
  end

end
