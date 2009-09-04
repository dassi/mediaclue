require 'zip/zip'
require 'ruport'

# Collection von Medium-Objekten.
class MediaSet < ActiveRecord::Base

  acts_as_ferret :remote => true, :fields => [:name, :desc, :tag_names]

  belongs_to :user
  
  has_many_polymorphs :collectables, :from => [:images, :documents, :audio_clips],
                                     :through => :media_set_memberships,
                                     :order => 'media_set_memberships.position'

  validates_associated :collectables, :message => "Mindestens ein enthaltenes Medium ist ungültig"
  validates_presence_of :name, :message => 'Name einer Kollektion ist zwingend erforderlich!', :on => :update
#  validates_presence_of :tags, :message => 'Mindestens ein Schlagwort ist zwingend erforderlich!'

  after_save :save_collectables, :save_new_tags

  attr_writer :tag_names
  
  def validate_on_update
    if self.collectables.empty?
      errors.add nil, 'Die Kollektion enthält keine Medien.'
    end

    validate_new_tag_names
  end
                                  
  acts_as_authorizable

  # TODO: Diese state machine ist evt. nicht ganz die richtige Wahl für den Zweck.

  acts_as_state_machine :initial => :created
  state :created
  state :uploading
  state :search_result
  state :composing
  state :owning 
  state :defining#, :enter => Proc.new {|ms| ms.update_attributes! :name => "Kollektion #{ms.id}" if ms.name.nil? or ['search_result','composing','uploading'].include?(ms.state) }
  state :defined

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
  
  def images_for_user_as_viewer(user)
    self.images.reject { |medium| !(user.is_viewer_of?(medium) or user.is_owner_of?(medium)) }
  end
  
  def collectables_for_user_as_viewer(user)
    self.collectables.reject { |medium| !(user.is_viewer_of?(medium) or user.is_owner_of?(medium)) }    
  end
  
  def collectables_for_user_as_owner(user)    
    self.collectables.reject { |medium| !user.is_owner_of?(medium) }    
  end
  
  def owner_name
    has_owner.first.full_name
  end 
  
  def caption
    if not name.blank?
      name
    else
      "Kollektion Nr. #{id}"
    end
  end
  
  def tag_names
    @tag_names ||= tags.to_s
  end
  
  # Setter für nested Form-Parameter für die enthaltenen Medien-Objekte
  def media_attributes=(media_attributes)
    collectables.each do |media|
      attributes = media_attributes[media.id.to_s] if media_attributes
      media.attributes = attributes if attributes
    end
  end
  
  # Packt alle Medien des Sets in ein ZIP-File und gibt den Filenamen zurück
  def to_zip_for_user(user)
    filename = File.join RAILS_ROOT, 'tmp', "#{File.sanitize_filename(name)}_ID#{id}.zip"

    File.delete filename if File.exists? filename
    Zip::ZipFile.open(filename, Zip::ZipFile::CREATE) do |zipfile|
      self.collectables_for_user_as_viewer(user).each_with_index do |medium, idx|
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
  
  def self.find_by_fulltext(fulltext)
    like_condition = "LIKE '%#{fulltext}%'"
    self.find :all, :conditions => "( (media_sets.name #{like_condition}) OR (media_sets.desc #{like_condition}))"
  end
  
  def self.find_media_ids_by_fulltext(fulltext)
    media_sets = find_by_fulltext(fulltext)
    media_sets.collect { |media_set| media_set.collectables.collect{ |media| media.id } }.flatten.uniq
  end                                           
  
  def self.find_media_with_ferret_for_user(query, user)
    all_found_media_sets = self.find_with_ferret(query)
    
    all_found_media = all_found_media_sets.collect(&:collectables).flatten.uniq
    
    # Rechte prüfen, auf jedem gefundenen Medium
    viewable_media = all_found_media.select { |m| user.is_viewer_of?(m) or user.is_owner_of?(m) }
    
    viewable_media
  end
  
  
  # Ruport Renderer, die eine Diashow der Medien des MediaSets als PDF erzeugt
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
  
  private #####################################################################
  
  def save_collectables
    collectables.each do |collectable|
      collectable.save(false)
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
  
end
