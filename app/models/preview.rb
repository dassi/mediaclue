class Preview < ActiveRecord::Base

  #
  # OPTIMIZE? Vielleicht kann hier mit Medium etwas gemeinsam verwendet werden. Vorläufig machen wir hier
  # jedoch Code Duplikation, weil Previews evt. in Zukunft komplett anders gespeichert werden als die Original-File
  #

  belongs_to :medium
  
  after_destroy :destroy_file

  # Liefert true, wenn das Preview erhältlich ist. Es kann temporär sein, dass das Preview noch nicht berechnet ist
  # von einem background job
  def available?
    File.exists?(self.full_filename)
  end

  # Used as the base path that #public_filename strips off full_filename to create the public path
  def base_path
    @base_path ||= File.join(RAILS_ROOT, 'public')
  end

  # Gets the public path to the file
  # The optional thumbnail argument will output the thumbnail's filename.
  def public_filename
    full_filename.gsub %r(^#{Regexp.escape(base_path)}), ''
  end

  # by default paritions files into directories e.g. 0000/0001/image.jpg
  # to turn this off set :partition => false
  def partitioned_path(*args)
    ("%08d" % medium.id).scan(/..../) + args
  end
  
  def full_filename
    File.join(RAILS_ROOT, PREVIEWS_STORAGE_PATH_PREFIX, *partitioned_path(self.filename))
  end
  
  # Destroys the file.  Called in the after_destroy callback
  def destroy_file
    FileUtils.rm(self.full_filename, :force => true)
    # remove directory also if it is now empty
    dir = File.dirname(full_filename)
    Dir.rmdir(dir) if File.exists?(dir) && (Dir.entries(dir)-['.','..']).empty?
  end
  
  
end