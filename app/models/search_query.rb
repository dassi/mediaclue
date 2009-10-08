class SearchQuery < ActiveRecord::Base

  include Authorization::ModelMethods

  belongs_to :user
  
  acts_as_list :scope => :user
  
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
  
end
