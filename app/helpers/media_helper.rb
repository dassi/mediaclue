module MediaHelper

  def medium_image_tag(medium, size = :small, options = {})
    # image_tag formatted_medium_url(:id => medium, :format => medium.ext, :size => size), options
    image_tag medium.public_filename(size), options
  end
  
  def medium_download_button(medium)
#    link_to 'herunterladen', formatted_medium_path(medium, medium.ext.to_sym)
    link_to image_tag('download.gif', :border => 0), formatted_medium_path(medium, medium.ext.to_sym), :title => 'Medium herunterladen'
  end

  def medium_download_link(medium, content = 'Herunterladen')
#    link_to 'herunterladen', formatted_medium_path(medium, medium.ext.to_sym)
    link_to content, formatted_medium_path(medium, medium.ext.to_sym)
  end
    
  def medium_add_to_collection_button(collection_media_set, medium)
    link_to_remote image_tag('plus.gif', :border => 0), {:url => add_media_set_medium_path(collection_media_set, medium), :method => :put}, {:title => 'Medium der aktuellen Auswahl hinzufügen'} if collection_media_set
  end
    
  def medium_remove_from_collection_button(collection_media_set, medium, options = {})
    link_to_remote image_tag('minus.gif', :border => 0), {:url => remove_media_set_medium_path(collection_media_set, medium, options), :method => :put, :confirm => "Medium '#{medium.name}' wirklich entfernen?"}, {:title => 'Medium aus der aktuellen Auswahl entfernen'}
  end
  
  def medium_remove_from_set_button(member_media_set, medium)
    link_to_remote image_tag('minus.gif', :border => 0), {:url => remove_media_set_medium_path(member_media_set, medium), :method => :put, :confirm => "Medium '#{medium.name}' wirklich aus dieser Kollektion entfernen (Medium selbst wird nicht gelöscht)?"}, {:title => 'Medium aus dieser Kollektion entfernen'} if member_media_set
  end

  def public_url
    request.protocol + request.host_with_port
  end
  
end
