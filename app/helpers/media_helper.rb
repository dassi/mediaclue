module MediaHelper

  def medium_image_tag(medium, size = :small, options = {})
    thumbnail = medium.image_thumbnail(size.to_s)
    if thumbnail && thumbnail.available?
      image_tag(medium.image_thumbnail(size.to_s).public_filename, options)
    else
      no_preview_text
    end
  end
  
  def medium_download_button(medium)
    link_to image_tag('download.gif', :class => 'icon'), medium_path(medium, :format => medium.ext.to_sym), :title => 'Medium herunterladen'
  end

  def medium_download_link(medium, content = 'Herunterladen')
    link_to content, medium_path(medium, :format => medium.ext.to_sym)
  end
    
  def medium_add_to_collection_button(collection_media_set, medium)
    link_to_remote image_tag('plus.gif', :class => 'icon'), {:url => add_media_media_set_path(collection_media_set, :medium_id => medium), :method => :put}, {:title => 'Medium der Zwischenablage hinzufügen'} if collection_media_set
  end
    
  def medium_remove_from_collection_button(collection_media_set, medium, options = {})
    link_to_remote image_tag('minus.gif', :class => 'icon'), {:url => remove_media_media_set_path(collection_media_set, options.merge(:medium_id => medium)), :method => :put, :confirm => "Medium '#{medium.name}' wirklich entfernen?"}, {:title => 'Medium aus der Zwischenablage entfernen'}
  end
  
  def medium_remove_from_set_button(member_media_set, medium)
    return if member_media_set.nil? or medium.nil?
    link_to_remote image_tag('minus.gif', :class => 'icon'), {:url => remove_media_media_set_path(member_media_set, :medium_id => medium), :method => :put, :confirm => "Medium '#{medium.name}' wirklich aus dieser Kollektion entfernen (Medium selbst wird nicht gelöscht)?"}, {:title => 'Medium aus dieser Kollektion entfernen'}
  end

  def public_url
    request.protocol + request.host_with_port
  end
  
end
