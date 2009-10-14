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

  has_many :media_set_memberships
  has_many :media_sets, :through => :media_set_memberships
                                                 
  has_many :user_group_permissions, :dependent => :destroy
  has_many :read_permitted_user_groups, :through => :user_group_permissions, :source => :user_group, :conditions => {:user_group_permissions => {:read => true}}
  has_many :write_permitted_user_groups, :through => :user_group_permissions, :source => :user_group, :conditions => {:user_group_permissions => {:write => true}}

  belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"
  
  # Validierungen
  validate :validate_new_tag_names
  validates_presence_of :name
  
  after_save :save_new_tags
  before_create :import_meta_data if FEATURE_METADATA
  
  # Auswahl für Quelle/Copytright
  # TODO: Als Model License auslagern
  SOURCE_SELECTIONS = [
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
  
  def self.find_with_ferret_for_user(query, user, options = {}, find_options = {})
    all_found_media = self.find_with_ferret(query, options, find_options)
    
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
    self.sub_classes.each { |sub_class| return sub_class if sub_class::CONTENT_TYPES.include? content_type }
    nil
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
    source_selection = Medium::SOURCE_SELECTIONS.find {|s| s.last == self.source }
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
  
  # Viewers von Form
  # TODO: Es tönt hier nach Mehrzahl "viewers", ist es aber nicht. So machen, dass es mehrere sein können!
  def viewers=(allowed_viewers)

# TODO

# #    is_public = false
#     
#     # Alle "viewer" Rollen entfernen
#     has_viewers.each { |viewer| accepts_no_role 'viewer', viewer }
#     
#     case allowed_viewers[0,5]
# #    when 'owner'
#       # Alle Viewer-Rollen entfernen
# #      has_viewers.each { |viewer| accepts_no_role 'viewer', viewer }
#       
# #    when 'other'
# #      is_public = true
#       
#     when 'group'
#       group_id = allowed_viewers.split('-').last
#       group = UserGroup.find(group_id)
#       accepts_role 'viewer', group if group
#     end
#     
#     nil
  end
    
  # Viewers für Form
  def viewers
    # TODO umschreiben nach read_permitted_groups
    # has_viewers.collect { |v| v.is_a?(UserGroup) ? "group-#{v.id}" : "owner" }.first
  end

  # Namen berechtigten Viewers (Besitzer, Gruppen, oder alle)
  def viewer_names
    # TODO umschreiben mit read_permitted_groups etc.
    # result = has_viewers.collect { |viewer| (viewer.is_a?(UserGroup) ? 'Gruppe ' : '') + viewer.full_name.titlecase }.join(', ')
    # result = 'nur Besitzer' if result.empty?
    # result
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

  # def original_file_extension
  #   File.extension(original_filename)
  # end
  
  def can_view?(user)
    (self.owner == user) or (self.read_permitted_user_groups.any? { |g| g.member?(user) })
  end

  def can_edit?(user)
    (self.owner == user) or (self.write_permitted_user_groups.any? { |g| g.member?(user) })
  end
  
end
