class Medium < ActiveRecord::Base
    
  include Authorization::ModelMethods
  include Authorization::GroupPermissions
  
  acts_as_ferret :remote => true, :fields => {:name => { :boost => 3 },
                                              :desc => { :boost => 2 },
                                              :tag_names => { :boost => 4 },
                                              :meta_data_values_for_ferret => { }}

  serialize :meta_data, Hash

  # Pagination, Anzahl pro Seite
  @@per_page = 20
  cattr_reader :per_page

  attr_writer :tag_names
  
  # Flag, ob wir Metadaten extrahieren beim Speichern
  attr_accessor :is_importing_metadata, :temp_path 

  has_many :media_set_memberships, :dependent => :destroy
  has_many :media_sets, :through => :media_set_memberships
                                                 
  belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"

  has_many :previews, :dependent => :destroy
  has_many :image_thumbnails, :foreign_key => 'medium_id'
  has_one :flash_preview, :foreign_key => 'medium_id'

  
  # Validierungen
  validate :validate_new_tag_names
  validates_presence_of :name
  
  after_save :save_new_tags

  ##############################################################
  before_validation :set_size_from_temp_path
  after_save :save_to_storage  # Das File speichern und temporäre Daten löschen. Muss NACH dem speichern passieren, weil die ID gebraucht wird für Pfad
  after_destroy :destroy_file

  define_callbacks :after_save_to_storage
  ##############################################################

  after_save_to_storage :create_previews_offloaded
    
  

  protected #######################################################################################

  def initialize(*args)
    super
    
    # Setzt default Flag, ob Metadaten aus dem File importiert werden sollen
    self.is_importing_metadata = true if self.is_importing_metadata.nil?
    
    # Default Rechte vergeben
    self.permission_type = DEFAULT_PERMISSION_TYPE if self.permission_type.nil?
    
  end
  
  # Taggt das Medium, sofern das Pseudo-Attribut tag_names gesetzt wurde
  def save_new_tags
    self.tag_with(@tag_names) if tags_changed?
  end
  
  def tags_changed?
    @tag_names && (@tag_names != self.tags.to_s)
  end

  def validate_new_tag_names
    Medium.parse_tags(@tag_names).each { |name| 
      errors.add :medium_tag_names, (Tag::TAG_ERROR_TEXT % name) unless Tag.new(:name => name).tag_name_valid?
    }
  end

  # Validiert, ob die angehängte Datei den zugelassenen Grenzen der Dateigrösse entspricht
  def validate_file_size
    # TODO
  end
  
  # Importiert Metadaten aus der angehängten Datei. Benutzt gem MiniExiftool
  def import_meta_data(filepath)
    # Mögliche Optionen:
    #   :composite => false
    exif_data = MiniExiftool.new(filepath, :convert_encoding => false).to_hash

    # Entfernen von unerwünschten EXIF-Tags
    for unwanted_exif_tag in UNWANTED_EXIF_TAGS
      exif_data.delete_if do |key, value|
        case unwanted_exif_tag
        when Regexp
          key =~ unwanted_exif_tag
        when String
          key == unwanted_exif_tag
        end
      end
    end
    
    # Entfernen von binären EXIF-Values
    # Exiftool schreibt z.B. "(Binary data 93321 bytes, use -b option to extract)" wenn es ein Binärdatenfeld ist
    exif_data.delete_if { |key, value| value =~ /^\(Binary data/ } 
    
    self.preprocess_meta_data(exif_data)
    
    self.meta_data = exif_data
    
    #
    # Schlagwörter setzen aus IPTC-Feld "Keywords"
    #
    
    exif_data.delete('Subject') # Remove also second keyword tag. We don't want to have the tags in the meta data anymore
    keywords = exif_data.delete('Keywords')
    if keywords
      keyword_tags = keywords.collect { |keyword| Tag.new(:name => keyword) }.select(&:tag_name_valid?)
      self.tag_names = Tag.tags_to_tag_names(keyword_tags)
    end
    
  rescue MiniExiftool::Error => e
    logger.error('Fehler beim Metadaten-Import: ' + e.message)
  end
  
  # Standard-Implementation. Soll von Subklassen überschrieben werden.
  # Bearbeitet EXIF-Daten, bevor sie gespeichert werden
  def preprocess_meta_data(exif_data_hash)
    # nichts tun
  end
  
  # Erzeugt die nötigen Preview-Dokumente. Delegiert an PreviewGenerator
  def create_previews_offloaded
    self.previews.clear
    PreviewGenerator.new(self).generate
    true
  end

  def meta_data_values_for_ferret
    meta_data.values.join(' ')
  end

  # Hilfsfunktion. Erzeugt einen YAML String aus einem Hash, mit sortierten keys.
  def hash_to_sorted_yaml(hash)
    return nil if hash.nil?
    YAML::quick_emit(hash.object_id) do |out|
      out.map(hash.taguri, hash.to_yaml_style) do |map|
        hash.sort.each do |k, v|
          map.add(k, v)
        end
      end
    end
  end
  
  public ##########################################################################################


  ##### BEGIN Attachment-Code. Braucht Überarbeitung #####################################

  # Copies the given file path to a new tempfile, returning the closed tempfile.
  def self.copy_to_temp_file(file, temp_base_name)
    returning Tempfile.new(temp_base_name, TEMP_PATH) do |tmp|
      tmp.close
      FileUtils.cp file, tmp.path
    end
  end


  # Writes the given data to a new tempfile, returning the closed tempfile.
  def self.write_to_temp_file(data, temp_base_name)
    tempfile = Tempfile.new(temp_base_name, TEMP_PATH)
    tempfile.binmode
    tempfile.write(data)
    tempfile.close
    
    tempfile.path
  end


  # Returns true if the attachment data will be written to the storage system on the next save
  def need_to_save_attachment?
    @need_to_save_attachment == true
    # File.file?(temp_path.to_s)
  end


  # This method handles the uploaded file object.  If you set the field name to uploaded_data, you don't need
  # any special code in your controller.
  def uploaded_data=(file_data)
    return nil if file_data.size == 0

    self.content_type = file_data.content_type

    # Wir erzeugen eine UUID als Filenamen, besser als den originalen Filenamen
    extension = File.extname(file_data.original_filename)
    self.filename = UUID.random_create.to_s + extension

    # Daten einlesen von temp-File oder Stream
    if file_data.is_a?(StringIO)
      file_data.rewind
      data = file_data.read
      if data.present?
        # temp_paths.unshift(write_to_temp_file(data))
        self.temp_path = write_to_temp_file(data)
        @need_to_save_attachment = true
      end
    else
      if file_data.present?
        # self.temp_paths.unshift(file_data)
        self.temp_path = file_data.respond_to?(:path) ? file_data.path : file_data.to_s
        @need_to_save_attachment = true
      end
    end
    
    process_attachment
  end


  # Copies the given file to a randomly named Tempfile.
  def copy_to_temp_file(file)
    self.class.copy_to_temp_file file, random_tempfile_filename
  end


  # Writes the given file to a randomly named Tempfile.
  def write_to_temp_file(data)
    self.class.write_to_temp_file(data, random_tempfile_filename)
  end


  def random_tempfile_filename
    "#{rand Time.now.to_i}#{filename || 'attachment'}"
  end

  # before_validation callback.
  def set_size_from_temp_path
    self.size = File.size(temp_path) if need_to_save_attachment?
  end

  # Destroys the file.  Called in the after_destroy callback
  def destroy_file
    FileUtils.rm full_filename
    # remove directory also if it is now empty
    Dir.rmdir(File.dirname(full_filename)) if (Dir.entries(File.dirname(full_filename))-['.','..']).empty?
  rescue SystemCallError
    logger.info "Exception destroying  #{full_filename.inspect}: [#{$!.class.name}] #{$1.to_s}"
  end

  
  # Saves the file to the file system
  def save_to_storage

    if need_to_save_attachment?
      FileUtils.mkdir_p(File.dirname(full_filename))
      FileUtils.cp(temp_path, full_filename)
      File.chmod(0644, full_filename)

      @need_to_save_attachment = false
      callback :after_save_to_storage
    end

  end


  # Liefert den absoluten Pfad der Datei
  def full_filename
    File.join(RAILS_ROOT, MEDIA_STORAGE_PATH_PREFIX, *partitioned_path(self.filename))
  end


  # Liefert ein Pfad-Segment nach dem Muster 0000/0001/image.jpg
  def partitioned_path(*args)
    raise 'ID muss beim Pfad generieren vorhanden sein!' if id.nil?
    ("%08d" % id).scan(/..../) + args
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


  # Subklassen können diese Method überschreiben, um das Attachment zu bearbeiten auf Bedarf, bevor es gespeichert wird
  def process_attachment
    import_meta_data(self.temp_path) if FEATURE_METADATA && self.is_importing_metadata
  end


  def ext
    ext = File.extname(self.filename)
    ext[1..-1] # Punkt an erster Stelle entfernen
  end
  

  ######################################################

  
  # Sucht Medien via Ferret, auf welchen der user Leseberechtigung hat
  def self.find_with_ferret_for_user(query, user, options = {}, find_options = {})

    # acts_as_ferret erwartet bei den conditions kein Hash, deshalb konvertieren
    if find_options[:conditions].is_a?(Hash)
      find_options[:conditions] = sanitize_sql_hash_for_conditions(find_options[:conditions])
    end

    # MediaSet immer includen, weil da conditions durch die find_options reinkommen können
    find_options[:include] = :media_sets
    
    all_found_media = self.find_with_ferret(query, options, find_options)
    
    # Rechte prüfen, auf jedem gefundenen Medium
    viewable_media = all_found_media.select { |m| m.can_view?(user) }
    
    viewable_media
  end
   
  # Sucht alle Medien auf welchen der user Leseberechtigung hat
  def self.find_all_for_user(user, find_options = {})

    # MediaSet immer includen, weil da conditions durch die find_options reinkommen können
    find_options[:include] = :media_sets

    all_found_media = self.find(:all, find_options)
    
    # Rechte prüfen, auf jedem gefundenen Medium
    viewable_media = all_found_media.select { |m| m.can_view?(user) }
    
    viewable_media
  end

   
  def self.sub_classes
#    self.send :subclasses
#    Object.subclasses_of(self.class)
    # TODO: Hm, hm, geht das nicht eleganter?
    [Image, AudioClip, Document, VideoClip]
  end
  
  def self.class_by_content_type(content_type)
    self.sub_classes.detect{ |sub_class| sub_class::CONTENT_TYPES.include?(content_type) }
  end

  # Liefert weitere erlaubte Dateiendungen. Für den Fall das die MIME-Library nicht ganz aktuell ist.
  # Default-Implementation. Soll in Subklassen überschrieben werden. Soll einen Hash liefern nach Muster:
  # {mime_typ => [ext, ...]}
  def self.additional_file_extensions
    {}
  end
  
  def self.file_extensions
    extensions = self.allowed_content_types.collect { |t| MIME::Types[t].first.extensions }.flatten
    extensions.concat(self.additional_file_extensions.values.flatten)
    extensions.compact.uniq
  end
  
  def self.all_media_file_extensions
    self.sub_classes.collect { |medium_class| medium_class.file_extensions }.flatten.compact.uniq
  end
  
  def self.allowed_content_types
    self.const_get(:CONTENT_TYPES)
  end

  def self.all_media_content_types   
    self.sub_classes.collect { |medium_class| medium_class.allowed_content_types }.flatten.compact.uniq
  end

  def template_path
    self.class.to_s.tableize
  end
  
  def format
    # TODO: Mime-text ist nichtssagend. Besser beschreibenden Text nehmen, irgendwoher
    content_type.split('/').last.upcase
  end
  
  # Liefert einen aussagekräftigeren Filenamen als der GUID-basierte Filenamen auf dem Speichermedium
  def pretty_filename

    filename_parts = []
    
    # Sofern der Name des Mediums sich vom Original-Filenamen unterscheidet, dann nehmen wir ihn in den Dateinamen rein
    if self.name != self.original_filename
      filename_parts << File.sanitize_filename(self.name)
    end
    
    filename_parts << self.original_filename
    
    filename_parts.join('--')
    
  end

  # Quelle in verständlichem Text
  def formatted_source
    source_selection = MEDIUM_SOURCES.find {|s| s.last == self.source }
    source_selection.try(:first)
  end
  
  # Name des Besitzers
  def owner_name
    owner.try(:full_name)
  end
  
  # Liste aller MediaSets mit den Status defined
  def defined_media_sets
    media_sets.find :all, :conditions => {:state => 'defined'}
  end

  def self.type_display_name
    "Medium"
  end
  
  def self.type_display_name_plural
    "Medien"
  end
  
  # Convenience-Methode auf Instanz
  def type_display_name
    self.class.type_display_name
  end
  
  def type_display_name_plural
    self.class.type_display_name_plural
  end
  

  def tag_names
    @tag_names ||= tags.to_s
  end

  def has_preview?
    not self.previews.empty?
  end
  
  def preview(name)
    self.previews.find(:first, :conditions => {:name => name.to_s})
  end

  def image_thumbnail(name)
    thumbnail = self.image_thumbnails.find(:first, :conditions => {:name => name.to_s})
    
    # TODO: Besseres on-the-fly generieren, hier schon mal als Software-Stub
    thumbnail ||= ImageThumbnail.new(:medium => self, :name => name, :filename => 'undefined.txt')
    
    thumbnail
  end
  
  def recreate_previews
    self.create_previews_offloaded
  end

  # Accessors für virtuelles Attribut meta_data_yaml für die Bearbeitung der Metadaten in einem Form
  def meta_data_yaml
    self.hash_to_sorted_yaml(self.meta_data)
  end
  def meta_data_yaml=(yaml)
    data = YAML::load(yaml)
    # Sicherstellen, dass nur Hashes geschrieben werden. Sonst Daten ignorieren
    if data.is_a?(Hash) && (data != self.meta_data)
      self.meta_data = data
    end
  end


  # Liest die Metadaten vom Originalfile erneut ein
  def reread_meta_data
    import_meta_data(self.full_filename)
    save!
  end

  def media_sets_for_user_as_viewer(user)
    self.defined_media_sets.reject { |media_set| !(user.can_view?(media_set)) }
  end

  # Liefert, ob der Datensatz geändert wurde, und ob er deshalb gespeichert werden muss.
  # Dies steht über dem üblichen Rails Dirty Mechanismus, weil wir noch weitere virtuelle Daten
  # speichern.
  def changed?
    value = super || tags_changed?
    value
  end
    
end
