# Collection von Medium-Objekten.
class MediaSet < ActiveRecord::Base

  include Authorization::ModelMethods
  
  acts_as_ferret :remote => true, :fields => {:name => { },
                                              :desc => { },
                                              :tag_names => { :boost => 2 }}

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
  state :composing      # "Sammelkollektion"
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
  
  # TODO: Warum brauchts das hier?! Mitunter verlangsamt das extrem das Speichern eines Sets, weil attachment_fu alle Bilder-Thumbnails nochmals erzeugt!!!
  # Evt. auch ein Fall für neues Feature von Rails 2.3, welches assoziationen mitspeichern kann? Auf jedenfall evt. auch smarter machen und nur geänderte speichern
  # Gemacht: Prüfung auf changed?, dies muss aber noch verifiziert werden, ob das was bringt
  def save_media
    media.each do |medium|
      medium.save(false) if medium.changed?
    end
  end

  def save_new_tags
    self.tag_with(@tag_names) if @tag_names
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
    self.media.images.reject { |medium| !(user.can_view?(medium)) }
  end
  
  def media_for_user_as_viewer(user)
    self.media.reject { |medium| !(user.can_view?(medium)) }
  end
  
  def media_for_user_as_owner(user)    
    self.media.reject { |medium| !user.is_owner_of?(medium) }
  end
  
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
        caption = 'Sammelkollektion' + state_name_postfix
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
#    files = self.images_for_user_as_viewer(user).collect { |image| image.public_filename(:pdfslideshow) }
#    PdfSlideShowController.render_pdf :filename => filename, :image_files => files, :name => self.name, :desc => self.desc
     PdfSlideShowController.render_pdf :filename => filename, 
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
    
    all_found_media_sets = self.find_with_ferret(query, options, find_options)
    
    all_found_media = all_found_media_sets.collect(&:media).flatten.uniq
    
    # Rechte prüfen, auf jedem gefundenen Medium
    viewable_media = all_found_media.select { |m| m.can_view?(user) }
    
    viewable_media
  end
  
  def self.find_all_media_for_user(user, find_options = {})
    # Media immer includen, weil da conditions durch die find_options reinkommen können
    find_options[:include] = :media

    all_found_media_sets = self.find(:all, find_options)
    
    all_found_media = all_found_media_sets.collect(&:media).flatten.uniq
    
    # Rechte prüfen, auf jedem gefundenen Medium
    viewable_media = all_found_media.select { |m| m.can_view?(user) }
    
    viewable_media
  end
  
  
  # Ruport Renderer, die eine Diashow der Medien des MediaSets als PDF erzeugt
  # TODO: Auslagern ein besseren Ort
  class PdfSlideShowController < Ruport::Controller
    stage :slide_show
    required_option :filename, :media_set, :images

    class PDF < Ruport::Formatter::PDF    
      renders :pdf, :for => PdfSlideShowController        
      proxy_to_pdf_writer

      build :slide_show do
        #options.paper_size = 'A4'
        options.paper_size = [21, 28]
        options.paper_orientation = :landscape      
        options.text_format = { :font_size => 12 }      
        catalog.page_mode = 'FullScreen'

#        fill_color Color::RGB::Black
#        rectangle(0, 0, page_width, page_height).fill

        select_font 'Helvetica'
#        fill_color Color::RGB::White
        add_text options.media_set.caption.to_latin1, :font_size => 24 if options.media_set.caption
        add_text ' '
        add_text options.media_set.desc.to_latin1, :font_size => 12 if options.media_set.desc
        add_text ' '
        add_text "Schlagworte: #{options.media_set.tags.to_s.to_latin1}", :font_size => 12 if options.media_set.desc
        add_text ' '
        add_text "Bilder:", :font_size => 12
        add_text ' '
        
        table = Ruport::Data::Table.new :data => options.images.collect { |image| [image.name.to_latin1, image.original_filename.to_latin1, image.desc ? image.desc[0..80].to_latin1 : '', image.tags.to_s.to_latin1] },
                                        :column_names => ['Name', 'Dateiname', 'Beschreibung (Anriss)', 'Schlagworte']
        
        options.table_format = {:width => 720, :font_size => 8}        
        draw_table table
        
#        for image in options.images
#          add_text "- #{image.name} (#{image.original_filename})", :font_size => 8
#        end

        for image_file in options.images.collect { |image| image.full_filename(:pdfslideshow) }
          start_new_page true
          fill_color Color::RGB::Black
          rectangle(0, 0, page_width, page_height).fill
          begin
            center_image_in_box image_file, :x => 0, :y => 0, :width => 796, :height => 597
          rescue TypeError
#            logger.error "Error adding image to PDF-slideshow: " + $!
            puts "Error adding image to PDF-slideshow: " + $!
          end
        end

        save_as options.filename
      end
    end      
  end  

  def can_view?(user)
    self.owner == user
  end

  def can_edit?(user)
    self.owner == user
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
  
end
