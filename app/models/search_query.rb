class SearchQuery < ActiveRecord::Base

  attr_accessor :younger_than # Schwellen-Datum, um nur nach neueren Medien zu suchen

  include Authorization::ModelMethods

  belongs_to :user
  
  acts_as_list :scope => :user

  named_scope :with_notifications_enabled, :conditions => {:notifications_enabled => true}

  protected #######################################################################################
  
  def self.sql_hash_to_string(a_hash)
    sanitize_sql_hash_for_conditions(a_hash)
  end
  
  public ##########################################################################################
  
  # Liefert true, wenn nach *allen* Medium-Typen gesucht wird
  def all_media_types?
    images? && video_clips? && audio_clips? && documents?
  end
  
  # Liefert einen Array mit Medium-Klassen, welche durchsucht werden sollen
  def media_types_classes
    [(images? ? Image : nil),
     (video_clips? ? VideoClip : nil),
     (audio_clips? ? AudioClip : nil),
     (documents? ? Document : nil)].compact
  end
  
  def media_type?(klass)
    media_types_classes.include?(klass)
  end

  def can_view?(subject_user)
    self.user == subject_user
  end

  def can_edit?(subject_user)
    self.user == subject_user
  end

  # Führt die Suchanfrage durch und erstellt ein SearchResult Objekt
  def execute

    search_result = SearchResult.new(self)
    
    find_options = {}
    find_options[:conditions] = {}
    find_options[:limit] = MAX_SEARCH_RESULTS
    
    
    if self.my_media_only?
      find_options[:conditions][:media_sets] ||= {} # Lazy erstellen, da ein leerer Hash Rails nicht gerne hat beim Umsetzen in SQL
      find_options[:conditions][:media_sets][:owner_id] = self.user.id
    end

    if not self.all_media_types?
      klasses = self.media_types_classes.collect(&:to_s)

      # Filtern, falls nicht alle angewählt sind
      find_options[:conditions][:media] ||= {}
      find_options[:conditions][:media][:type] = klasses
      
    end
    
    search_with_ferret = (not self.ferret_query.blank?)

    find_options_for_medium = find_options.dup
    find_options_for_media_set = find_options.dup

    if @younger_than
      # In Text umwandeln, damit wir den SQL-Datumsvergleich einfügen können. (Ach! Ich liebe ActiveRecord...)
      sql = self.class.sql_hash_to_string(find_options[:conditions])
      sql = nil if sql.blank?
      find_options_for_medium[:conditions]    = [sql, "media.updated_at > '#{@younger_than.to_formatted_s(:db)}'"].compact.join(' AND ')
      find_options_for_media_set[:conditions] = [sql, "media_sets.updated_at > '#{@younger_than.to_formatted_s(:db)}'"].compact.join(' AND ')
    end
    
    # Suche per ferret, oder direkt in der DB
    if search_with_ferret
      ferret_options = {:limit => MAX_SEARCH_RESULTS}
      media = Medium.find_with_ferret_for_user(self.ferret_query, self.user, ferret_options, find_options_for_medium)
      media_sets_and_media = MediaSet.find_media_with_ferret_for_user(self.ferret_query, self.user, ferret_options, find_options_for_media_set)
    else
      media = Medium.find_all_for_user(self.user, find_options_for_medium)
      media_sets_and_media = MediaSet.find_all_media_for_user(self.user, find_options_for_media_set)
    end

    # Gefundene Medien in Suchresultat abspeichern
    search_result.add_media(media)
    search_result.add_media_sets_and_media(media_sets_and_media)
    
    # Gefundene Medien auch in das spezielle Suchresultat-Set des Users abspeichern (welches einfach alle )
    media_from_sets = media_sets_and_media.collect { |media_set, media_in_set| media_in_set }.flatten.uniq
    found_media = (media + media_from_sets).uniq
    media_set = self.user.search_result_media_set
    media_set.clear
    media_set.media << found_media
    media_set.save_without_validation
    
    search_result.media_set = media_set

    search_result
  end
  
  def toggle_notifications
    self.notifications_enabled = (not self.notifications_enabled)
    self.last_notification_datetime = DateTime.now
    self.save!
  end
  
end
