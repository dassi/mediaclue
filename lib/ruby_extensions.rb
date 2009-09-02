
class String
  require 'iconv'
  @@iso_converter     = Iconv.new('ISO-8859-15','UTF-8')
  @@latin_converter   = Iconv.new('ISO-8859-1','UTF-8')
  @@ansi_converter    = Iconv.new('MS-ANSI','UTF-8')
  @@windows_converter = Iconv.new('WINDOWS-1252','UTF-8')
  
  def to_iso
    @@iso_converter.iconv(self)
  end

  def to_latin1
    @@latin_converter.iconv(self)
  end  

  def to_ansi
    @@ansi_converter.iconv(self)
  end

  def to_windows
    @@windows_converter.iconv(self)
  end
  
  def ellipsis(count)
    result = slice(0..(count-1))
    result += '...' if length > count
    result
  end
end


class File
  def self.abbr_filename(file_name, length = 30)
    ext = File.extname(file_name)    
    basename = File.basename(file_name, ext)
    if basename.length > length
      "#{basename[0,length]}[..]#{ext}"  
    else
      file_name
    end    
  end

  def self.sanitize_filename(filename)

    # Handling von nil
    filename ||= 'Unbenannt'
    
    returning filename.strip do |name|
      # NOTE: File.basename doesn't work right with Windows paths on Unix
      # get only the filename, not the whole path
      name.gsub!(/^.*(\\|\/)/, '')
      
      # Finally, replace all non alphanumeric, underscore or periods with underscore
      name.gsub!(/[^\w\.\-]/, '_')
    end
  end

end