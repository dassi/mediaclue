class Medium < ActiveRecord::Base

  acts_as_ferret :remote => true, :fields => [:name, :desc, :tag_names, :meta_data]

  @@per_page = 20
  
  cattr_reader :per_page
  attr_writer :tag_names
  
  # Flag, ob wir Metadaten extrahieren beim Speichern
  attr_accessor :is_importing_metadata 
  
  validate :validate_new_tag_names
  validates_presence_of :name, :message => 'Name ist zwingend erforderlich!'
#  validates_presence_of :tags, :message => 'Mindestens ein Schlagwort ist zwingend erforderlich!'  
  
  acts_as_authorizable
  
  # after_create :set_default_viewer
  after_save :save_new_tags
  before_create :import_meta_data if FEATURE_METADATA
  
  # Auswahl für Quelle/Copytright
  SOURCE_SELECTIONS = [
    # ['', nil],
    ['Unbekannt', 'unknown'],
    ['Netzklau (nur für persönlichen Gebrauch)', 'personal'],
    ['Schulcopyright (offiziell für Schulzwecke lizensiert)', 'school'],
    ['Frei (Creative Commons Licence)', 'free']
  ]

  protected #######################################################################################

  def initialize(*args)
    super
    
    @is_importing_metadata ||= true
    
  end
  
  def save_new_tags
    self.tag_with(@tag_names) if @tag_names
  end

  def validate_new_tag_names
    Medium.parse_tags(@tag_names).each { |name| 
      errors.add :medium_tag_names, (Tag::TAG_ERROR_TEXT % name) unless Tag.new(:name => name).tag_name_valid?
    }
  end
  
  def import_meta_data
    # Hinweis: Evt. muss hier mit self.full_filename gearbeitet werden, aber zu creation-Zeitpunkt gibt es dieses File noch nicht.
    # attachment_fu kopiert es erst nach dem save dorthin. Bis dahin ist es in temp_path
    if self.is_importing_metadata
      self.meta_data = MiniExiftool.new(self.temp_path).to_yaml
    end
  end
  
  public ##########################################################################################
  
  def self.find_with_ferret_for_user(query, user)
    all_found_media = self.find_with_ferret(query)
    
    # Rechte prüfen, auf jedem gefundenen Medium
    viewable_media = all_found_media.select { |m| user.is_viewer_of?(m) or user.is_owner_of?(m) }
    
    viewable_media
  end
   
  def self.sub_classes
#    self.send :subclasses
#    Object.subclasses_of(self.class)
    # TODO: Hm, hm, geht das nicht eleganter?
    [Image, AudioClip, Document, VideoClip]
  end
  
  def self.class_by_content_type(content_type)
    self.sub_classes.each { |sub_class| return sub_class if sub_class::CONTENT_TYPES.include? content_type }
    nil
  end
  
  def self.all_media_file_extensions
    self.all_media_content_types.collect { |t| MIME::Types[t].first.extensions }.flatten.compact.uniq
  end
  
  def self.all_media_content_types   
    self.sub_classes.collect { |medium_class| medium_class::CONTENT_TYPES }.flatten.compact.uniq
  end

  def template_path
    self.class.to_s.tableize
  end
  
  def format
    content_type.split('/').last.upcase    
  end
  
  def filesize
    "#{size / 1024} kB"
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
    source_selection = Medium::SOURCE_SELECTIONS.find {|s| s.last == self.source }
    (source_selection || ['keine Angabe']).first 
  end
  
  # Name des Besitzers
  def owner_name
    has_owner.first.full_name
  end
  
  # Liste aller MediaSets mit den Status defined
  def defined_media_sets
    media_sets.find :all, :conditions => {:state => 'defined'}
  end
  
  # Viewers von Form
  # TODO: Es tönt hier nach Mehrzahl "viewers", ist es aber nicht. So machen, dass es mehrere sein können!
  def viewers=(allowed_viewers)
#    is_public = false
    
    # Alle "viewer" Rollen entfernen
    has_viewers.each { |viewer| accepts_no_role 'viewer', viewer }
    
    case allowed_viewers[0,5]
#    when 'owner'
      # Alle Viewer-Rollen entfernen
#      has_viewers.each { |viewer| accepts_no_role 'viewer', viewer }
      
#    when 'other'
#      is_public = true
      
    when 'group'
      group_id = allowed_viewers.split('-').last
      group = UserGroup.find(group_id)
      accepts_role 'viewer', group if group
    end
    
    nil
  end
    
  # Viewers für Form
  def viewers
    has_viewers.collect { |v| v.is_a?(UserGroup) ? "group-#{v.id}" : "owner" }.first
  end

  # Namen berechtigten Viewers (Besitzer, Gruppen, oder alle)
  def viewer_names
    result = has_viewers.collect { |viewer| (viewer.is_a?(UserGroup) ? 'Gruppe ' : '') + viewer.full_name.titlecase }.join(', ')
    result = 'nur Besitzer' if result.empty?
    result
  end  
  
  # # Setzt die Default User Gruppe (die Gruppe Lehrer als Viewer dieses Mediums)
  # def set_default_viewer
  #   group = UserGroup.find(DEFAULT_GROUP_ID)
  #   accepts_role 'viewer', group if group   
  # end
  
  # TODO: entfernen, weil scheinbar nicht verwendet
  # True, falls ein Attribut dieses Objekts von den Daten params abweicht
  def attr_changes?(params)
    raise 'sollte nicht aufgerufen werden?!'
#    p=params.reject {|k,v| !['name', 'desc'].include? k }
    params.each do |key, value|
      # Sichtbarkeit "nur Besitzer" ist so realisiert, dass das Medium keine Viewers besitzt.
      if key == 'viewers'        
        return true if viewers.nil? and value != 'owner'
      else        
        return true if self.send(key) != value
      end
    end
    
    false
  end

  def type_display_name
    "Medium"
  end

  def tag_names
    @tag_names ||= tags.to_s
  end

  
end
