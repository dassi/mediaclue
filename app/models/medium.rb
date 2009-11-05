class Medium < ActiveRecord::Base
    
  include Authorization::ModelMethods
  
  acts_as_ferret :remote => true, :fields => {:name => { :boost => 2 },
                                              :desc => { :boost => 2 },
                                              :tag_names => { :boost => 3 },
                                              :meta_data => { }}

  # Pagination, Anzahl pro Seite
  @@per_page = 20
  cattr_reader :per_page

  attr_writer :tag_names
  
  # Flag, ob wir Metadaten extrahieren beim Speichern
  attr_accessor :is_importing_metadata 

  has_many :media_set_memberships, :dependent => :destroy
  has_many :media_sets, :through => :media_set_memberships
                                                 
  has_many :user_group_permissions, :dependent => :destroy, :autosave => true
  has_many :read_permitted_user_groups, :through => :user_group_permissions, :source => :user_group, :conditions => {:user_group_permissions => {:read => true}}
  has_many :write_permitted_user_groups, :through => :user_group_permissions, :source => :user_group, :conditions => {:user_group_permissions => {:write => true}}

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
  after_validation :process_attachment  # Das raufgeladene File bearbeiten
  after_save :after_process_attachment  # Das File speichern und temporäre Daten löschen
  after_destroy :destroy_file

  # attr_accessible :uploaded_data
  define_callbacks :after_attachment_saved
  ##############################################################

  after_attachment_saved :create_previews_offloaded
  after_attachment_saved :import_meta_data if FEATURE_METADATA
    
  

  protected #######################################################################################

  def initialize(*args)
    super
    
    # Setzt default Flag, ob Metadaten aus dem File importiert werden sollen
    @is_importing_metadata ||= true
    
  end
  
  # Taggt das Medium, sofern das Pseudo-Attribut tag_names gesetzt wurde
  def save_new_tags
    # OPTIMIZE? Nur speichern, sofern tag_names sich verändert hat?
    self.tag_with(@tag_names) if @tag_names
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
  def import_meta_data
    if self.is_importing_metadata
      begin
        self.meta_data = MiniExiftool.new(self.full_filename).to_yaml
      rescue MiniExiftool::Error
        self.meta_data = 'Fehler beim Metadaten-Import'
      end
    end
  end
  
  # Erzeugt die nötigen Preview-Dokumente. Delegiert an PreviewGenerator
  def create_previews_offloaded
    self.previews.clear
    PreviewGenerator.new(self).generate
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
    returning Tempfile.new(temp_base_name, TEMP_PATH) do |tmp|
      tmp.binmode
      tmp.write data
      tmp.close
    end
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
        temp_paths.unshift(write_to_temp_file(data))
        @need_to_save_attachment = true
      end
    else
      if file_data.present?
        self.temp_paths.unshift(file_data)
        @need_to_save_attachment = true
      end
    end
  end


  # Gets the latest temp path from the collection of temp paths.  While working with an attachment,
  # multiple Tempfile objects may be created for various processing purposes (resizing, for example).
  # An array of all the tempfile objects is stored so that the Tempfile instance is held on to until
  # it's not needed anymore.  The collection is cleared after saving the attachment.
  def temp_path
    p = temp_paths.first
    p.respond_to?(:path) ? p.path : p.to_s
  end


  # Gets an array of the currently used temp paths.  Defaults to a copy of #full_filename.
  def temp_paths
    @temp_paths ||= (new_record? || !File.exist?(full_filename) ? [] : [copy_to_temp_file(full_filename)])
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


  # Creates a temp file from the currently saved file.
  def create_temp_file
    copy_to_temp_file full_filename
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
  rescue
    logger.info "Exception destroying  #{full_filename.inspect}: [#{$!.class.name}] #{$1.to_s}"
    logger.warn $!.backtrace.collect { |b| " > #{b}" }.join("\n")
  end

  
  # Saves the file to the file system
  def save_to_storage
    # TODO: This overwrites the file if it exists, maybe have an allow_overwrite option?
    FileUtils.mkdir_p(File.dirname(full_filename))
    File.cp(temp_path, full_filename)
    # File.chmod(attachment_options[:chmod] || 0644, full_filename)
    File.chmod(0644, full_filename)
    @old_filename = nil
    true
  end

  
  def current_data
    File.file?(full_filename) ? File.read(full_filename) : nil
  end


  # Gets the full path to the filename in this format:
  #
  #   # This assumes a model name like MyModel
  #   # public/#{table_name} is the default filesystem path 
  #   RAILS_ROOT/public/my_models/5/blah.jpg
  #
  # Overwrite this method in your model to customize the filename.
  # The optional thumbnail argument will output the thumbnail's filename.
  def full_filename
    File.join(RAILS_ROOT, MEDIA_STORAGE_PATH_PREFIX, *partitioned_path(self.filename))
  end


  # by default paritions files into directories e.g. 0000/0001/image.jpg
  # to turn this off set :partition => false
  def partitioned_path(*args)
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
    # @saved_attachment = save_attachment?
  end

  # Cleans up after processing.  Thumbnails are created, the attachment is stored to the backend, and the temp_paths are cleared.
  def after_process_attachment
    if need_to_save_attachment?
      save_to_storage
      @temp_paths.clear if @temp_paths
      @need_to_save_attachment = false
      # @saved_attachment = nil
      callback :after_attachment_saved
    end
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
  
  # Gibt in lesbarer Form die Leserechte zurück
  def read_permissions_description
    case self.permission_type
    when 'all'
      'Alle'
    when 'owner'
      'Nur Besitzer'
    when 'groups'
      self.read_permitted_user_groups.collect(&:full_name).join(', ')
    end
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

  def can_view?(user)
    case self.permission_type
    when 'all'
      true
    when 'owner'
      (self.owner == user)
    when 'groups'
      (self.owner == user) || (self.read_permitted_user_groups.any? { |g| g.member?(user) })
    else
      false
    end
  end

  def can_edit?(user)
    (self.owner == user) or (self.write_permitted_user_groups.any? { |g| g.member?(user) })
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

  
  # Spezialisierter Setter
  def read_permitted_user_group_ids=(ids)
  
    # TODO! Wenn einmal auch write-Permissions tatsächlich verwendet werden, dann ist diese Funktion nicht mehr korrekt
    # Dann müsste man statt blanko löschen, jeden einzelnen Eintrag suchen updaten, und restliche löschen, oder so ähnlich
    
    self.user_group_permissions.clear

    if ids && ids.any?
      for group_id in ids
        self.user_group_permissions.build(:user_group_id => group_id.to_i, :read => true)
      end
    end
    
  end
  
end
