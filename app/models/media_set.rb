if LOCAL_DEVELOPMENT
  require_dependency 'ruport_extensions'
end

# Collection von Medium-Objekten.
class MediaSet < ActiveRecord::Base

  include Authorization::ModelMethods
  include Authorization::GroupPermissions
  
  acts_as_ferret :remote => true, :boost => :rating,
                 :fields => {:name => { :boost => 2 },
                             :desc => { },
                             :tag_names => { :boost => 3 }}

  belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"
  
  has_many :media_set_memberships
  has_many :media, :through => :media_set_memberships, :order => 'media_set_memberships.position ASC' do
    def images
      find(:all, :conditions => ['media.type = ?', 'Image'])
    end
    
    def audio_clips
      find(:all, :conditions => ['media.type = ?', 'AudioClip'])
    end
    
    def video_clips
      find(:all, :conditions => ['media.type = ?', 'VideoClip'])
    end
    
    def documents
      find(:all, :conditions => ['media.type = ?', 'Document'])
    end
  end

  validates_associated :media, :message => "Mindestens ein enthaltenes Medium ist ungültig"
  validates_presence_of :name, :on => :update
  validates_numericality_of :rating, :only_integer => true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 3, :allow_nil => false

  after_save :save_media, :save_new_tags

  attr_writer :tag_names
  
  def validate_on_update
    if self.media.empty?
      errors.add nil, 'Die Kollektion enthält keine Medien.'
    end

    validate_new_tag_names
  end
                                  
  # TODO: Diese state machine ist evt. nicht ganz die richtige Wahl für den Zweck. Z.B. state uloading, search_result, composing sind nicht wirklich Zustände der Kollektion, sondern Kontexte

  acts_as_state_machine :initial => :created
  
  state :created        # "Erzeugt"
  state :uploading      # "Aktuelle Hochlade Kollektion"
  state :search_result  # "Letztes Suchergebnis"
  state :composing      # "Zwischenablage"
  state :owning         # "Meine Medien"
  state :defining       # "noch zu vervollständigen"
  state :defined        # "Vollständig definiert, alles OK"

  event :upload do
    transitions :from => :created, :to => :uploading
  end

  event :compose do
    transitions :from => :created, :to => :composing
    transitions :from => :defining, :to => :composing
    transitions :from => :defined, :to => :composing
  end
  
  event :own do
    transitions :from => :created, :to => :owning
  end  

  event :to_search_result do
    transitions :from => :created, :to => :search_result
  end  
  
  event :define do
    transitions :from => :uploading, :to => :defining
    transitions :from => :composing, :to => :defining
    transitions :from => :search_result, :to => :defining
  end

  event :store do
    transitions :from => :defining, :to => :defined
  end


  protected #######################################################################################
  
  # Hinweis: Kein Fall für neues Feature von Rails 2.3, welches Assoziationen mitspeichern kann mit :autosave => true! (Das würde IMMER speichern)
  def save_media
    media.each do |medium|
      medium.save(false) if medium.changed?
    end
  end

  def save_new_tags
    self.tag_with(@tag_names) if tags_changed?
  end

  def tags_changed?
    @tag_names && (@tag_names != self.tags.to_s)
  end

  def validate_new_tag_names
    tag_name_list = MediaSet.parse_tags(@tag_names)
    tag_name_list.each { |name| 
      errors.add :tag_names, (Tag::TAG_ERROR_TEXT % name) unless Tag.new(:name => name).tag_name_valid?
    }
    
    # wenn durch Array-differenz nicht ein kleinerer Array zurückkommt, d.h. kein fach enthalten ist
    unless (tag_name_list - SUBJECT_SELECTIONS).size < tag_name_list.size
      errors.add :tag_names, "Die Kollektion muss mindestens mit einem Fach verschlagwortet werden"
    end
  end

  public ##########################################################################################

  def self.used_sort_pathes
    self.connection.select_values('SELECT DISTINCT sort_path FROM media_sets WHERE (sort_path IS NOT NULL) AND (sort_path != "") ORDER BY sort_path ASC')
  end
  
  def images_for_user_as_viewer(user)
    self.media.images.viewable_only(user)
  end
  
  def media_for_user_as_viewer(user)
    self.media.reject { |medium| !(user.can_view?(medium)) }
  end
  
  def media_for_user_as_editor(user)
    self.media.reject { |medium| !(user.can_edit?(medium)) }
  end
  
  # Nicht gebraucht
  # def media_for_user_as_owner(user)    
  #   self.media.reject { |medium| !user.is_owner_of?(medium) }
  # end
  
  def owner_name
    owner.try(:full_name)
  end 
  
  def caption

    if not name.blank?
      caption = name
      state_name_postfix = " (#{name})"
    else
      caption = "Kollektion Nr. #{id}"
      state_name_postfix = ''
    end

    # Falls es ein spezielles MediaSet ist, dann den Namen speziell bilden
    case self.state
      when 'uploading'
        caption = 'Aktuelle Hochlade-Kollektion' + state_name_postfix
      when 'composing'
        caption = 'Zwischenablage' + state_name_postfix
      when 'search_result'
        caption = 'Letztes Suchresultat'
      when 'owning'
        caption = 'Meine Medien'
    end
    
    caption
    
  end
  
  def tag_names
    @tag_names ||= tags.to_s
  end
  
  # Setter für nested Form-Parameter für die enthaltenen Medien-Objekte
  # TODO: Evt. mit neuem Rails 2.3 nested forms (accepts_nested_attributes) vereinfachen!
  def media_attributes=(media_attributes)
    if media_attributes and media_attributes.any?
      media.each do |medium|
        attributes = media_attributes[medium.id.to_s]
        medium.attributes = attributes if attributes
      end
    end
  end
  
  # Packt alle Medien des Sets in ein ZIP-File und gibt den Filenamen zurück
  def to_zip_for_user(user)
    filename = File.join RAILS_ROOT, 'tmp', "#{File.sanitize_filename(name)}_ID#{id}.zip"

    File.delete filename if File.exists? filename
    Zip::ZipFile.open(filename, Zip::ZipFile::CREATE) do |zipfile|
      self.media_for_user_as_viewer(user).each_with_index do |medium, idx|
        filename_parts = [idx.to_s.rjust(3,'0')]
        
        zipfile.add "#{idx.to_s.rjust(3,'0')}_#{medium.pretty_filename}", medium.full_filename
      end
    end

    filename
  end
  
  
  def to_pdf_for_user(user)
    filename = File.join RAILS_ROOT, 'tmp', "#{File.sanitize_filename(name)}_ID#{id}.pdf"
#    files = self.images_for_user_as_viewer(user).collect { |image| image.image_thumbnail(:pdfslideshow).public_filename }
#    PdfSlideShowController.render_pdf :filename => filename, :image_files => files, :name => self.name, :desc => self.desc
     ::PdfSlideShowController.render_pdf :filename => filename, 
                                     :media_set => self,
                                     :images => self.images_for_user_as_viewer(user)
#                                    :name => self.name, 
#                                    :desc => self.desc, 
    filename
  end
  
  def self.find_media_with_ferret_for_user(query, user, options = {}, find_options = {})

    # acts_as_ferret erwartet bei den conditions kein Hash, deshalb konvertieren
    if find_options[:conditions].is_a?(Hash)
      find_options[:conditions] = sanitize_sql_hash_for_conditions(find_options[:conditions])
    end

    # Media immer includen, weil da conditions durch die find_options reinkommen können
    find_options[:include] = :media
    
    # Kollektionen suchen. Kollektionen entfernen für die keine Leseberechtigung da ist
    all_found_media_sets = self.find_with_ferret(query, options, find_options).reject { |ms| !(user.can_view?(ms)) }
    
    # all_found_media = all_found_media_sets.collect(&:media).flatten.uniq
    
    media_sets_and_media = {}
    all_found_media_sets.each do |ms|
      media_sets_and_media[ms] = ms.media_for_user_as_viewer(user)
    end
    
    # Rechte prüfen, auf jedem gefundenen Medium
    # viewable_media = all_found_media.select { |m| m.can_view?(user) }
    
    # viewable_media
    
    media_sets_and_media
  end
  
  # Performantere Variante ohne ferret-Suche
  def self.find_all_media_for_user(user, find_options = {})
    # Media immer includen, weil da conditions durch die find_options reinkommen können
    find_options[:include] = :media

    # Kollektionen suchen. Kollektionen entfernen für die keine Leseberechtigung da ist
    all_found_media_sets = self.find(:all, find_options).reject { |ms| !(user.can_view?(ms)) }

    # all_found_media = all_found_media_sets.collect(&:media).flatten.uniq

    media_sets_and_media = {}
    all_found_media_sets.each do |ms|
      media_sets_and_media[ms] = ms.media_for_user_as_viewer(user)
    end
    
    # # Rechte prüfen, auf jedem gefundenen Medium
    # viewable_media = all_found_media.select { |m| m.can_view?(user) }
    # 
    # viewable_media
    
    media_sets_and_media
  end
  
  def images
    media.images
  end
  
  def video_clips
    media.video_clips
  end
  
  def audio_clips
    media.audio_clips
  end
  
  def documents
    media.documents
  end
  
  def sort_path_array
    sort_path.to_s.split('/')
  end
  
  def sort_array
    sort_path_array << caption
  end
  
  def <=>(other_media_set)
    self.sort_array <=> other_media_set.sort_array
  end

  def clear
    self.media_set_memberships.clear
  end
end
