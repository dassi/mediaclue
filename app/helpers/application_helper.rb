# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def spiffy_top(class_base = 'medium')
    "<b class='#{class_base}'><b class='#{class_base}1'><b></b></b><b class='#{class_base}2'><b></b></b><b class='#{class_base}3'></b><b class='#{class_base}4'></b><b class='#{class_base}5'></b></b>"
  end

  def spiffy_bottom(class_base = 'medium')
    "<b class='#{class_base}'><b class='#{class_base}5'></b><b class='#{class_base}4'></b><b class='#{class_base}3'></b><b class='#{class_base}2'><b></b></b><b class='#{class_base}1'><b></b></b></b>"
  end

  def backlink
    link_to_function 'Zurück', 'history.back();'
  end
  
  def formatted_tag_list(tagged_model)
    tagged_model.tag_list.empty? ? no_data_text : tagged_model.tag_list
  end
  
  def formatted_desc(desc_model)
    if not desc_model.desc.blank?
      simple_format(desc_model.desc)
    else
      no_data_text
    end
  end
  
  def no_data_text
    content_tag('em', '[keine]')
  end
  
  def options_for_viewer
    [['nur Besitzer', 'owner']].concat(@user_groups.collect {|g| ["Gruppe #{g.full_name.titlecase}", g.id]})
  end
  
  # generiert eine id für html-elemente aus db-objekten
  #
  def dom_id(object, prefix=nil)
    display_id = object.new_record? ? "new" : object.id
    modified_class_name = object.class.name.underscore.gsub(/\//, '__')
    prefix = prefix.nil? ? modified_class_name : "#{prefix}_#{modified_class_name}"
    "#{prefix}_#{display_id}"
  end
  
  def subjects_link_list(dom_id)
    SUBJECT_SELECTIONS.collect{ |s| link_to_textfield_append_function(s, dom_id) }.join('<span> <span/>')    
  end
  
  # Liefert eine Link-Liste von den häufigsten Tags. Fach-Tags werden rausgenommen.
  def top_tags_link_list(dom_id, options = {})
    
    # Hole die häufigsten Tags (relativ zum Typ des getaggten Objektes)
    tags_from_media = Medium.tag_counts(options)
    tags_from_media_sets = MediaSet.tag_counts(options)

    # Füge die Liste zusammen, so dass die ersten Elemente beider Listen wieder an ersten Stellen sind
    # So sind die häufigst gebrauchten Tags zuerst, unabhängig ob in MediaSet oder Medium verwendet.
    tag_names = tags_from_media_sets.zip(tags_from_media).flatten.compact.uniq.collect(&:name)

    # Fach-Tags rausnehmen, die gehören nicht dazu
    # TODO: Das Limit (z.B. 30) stimmt hier danach nicht mehr, ist aber nicht so tragisch, aber unkorrekt.
    tag_names -= SUBJECT_SELECTIONS

    tag_names.collect{ |t| link_to_textfield_append_function(t, dom_id) }.join('&nbsp; ')    
  end

  # Liefert eine Link-Liste von den häufigsten Tags. Fach-Tags werden rausgenommen.
  def my_top_tags_link_list(dom_id, options = {})

    tagging_ids = (current_user.media_sets.collect(&:tagging_ids) + current_user.media.collect(&:tagging_ids)).flatten

    options[:conditions] = ['taggings.id IN (?)', tagging_ids]

    # Hole die häufigsten Tags (relativ zum Typ des getaggten Objektes)
    tags_from_media = Medium.tag_counts(options)
    tags_from_media_sets = MediaSet.tag_counts(options)

    # Füge die Liste zusammen, so dass die ersten Elemente beider Listen wieder an ersten Stellen sind
    # So sind die häufigst gebrauchten Tags zuerst, unabhängig ob in MediaSet oder Medium verwendet.
    tag_names = tags_from_media_sets.zip(tags_from_media).flatten.compact.uniq.collect(&:name)

    # Fach-Tags rausnehmen, die gehören nicht dazu
    # TODO: Das Limit (z.B. 30) stimmt hier danach nicht mehr, ist aber nicht so tragisch, aber unkorrekt.
    tag_names -= SUBJECT_SELECTIONS

    tag_names.collect{ |t| link_to_textfield_append_function(t, dom_id) }.join('&nbsp; ')    
  end

  # Liefert eine Link-Liste mit Tags, die am meisten in Kombination mit den given_tag_names vorkommen
  def related_tags_link_list(dom_id, given_tag_names, options = {})

    taggables = Medium.tagged_with(*given_tag_names) + MediaSet.tagged_with(*given_tag_names)

    tagging_ids = taggables.collect(&:tagging_ids).flatten
                         
    options[:limit] ||= 15
    options[:conditions] = ['taggings.id IN (?)', tagging_ids]

    # Hole die häufigsten Tags (relativ zum Typ des getaggten Objektes)
    tags_from_media = Medium.tag_counts(options)
    tags_from_media_sets = MediaSet.tag_counts(options)

    # Füge die Liste zusammen, so dass die ersten Elemente beider Listen wieder an ersten Stellen sind
    # So sind die häufigst gebrauchten Tags zuerst, unabhängig ob in MediaSet oder Medium verwendet.
    suggested_tag_names = tags_from_media_sets.zip(tags_from_media).flatten.compact.uniq.collect(&:name)

    # Fach-Tags rausnehmen, die gehören nicht dazu
    # TODO: Das Limit (z.B. 30) stimmt hier danach nicht mehr, ist aber nicht so tragisch, aber unkorrekt.
    suggested_tag_names -= SUBJECT_SELECTIONS
    suggested_tag_names -= given_tag_names

    if suggested_tag_names.any?
      suggested_tag_names.collect{ |t| link_to_textfield_append_function(t, dom_id) }.join('&nbsp; ')
    else
      no_data_text
    end
    
  end
  
  def link_to_textfield_append_function(name, field_id)
    # Testen, ob ein blank vorkommt, und dann den String mit Anführungszeichen einfassen
    if name.include?(' ')
      value = '"' + name + '"'
    else
      value = name
    end
    link_to_function(name, "append_link_value('#{field_id}', '#{value}')")
    # link_to_function(name) do |page|
    #   page << "append_link_value('#{field_id}', '#{value}')"
    # end
  end
  
  def close_tag_link_list(dom_id)
    link_to_function(image_tag('kreuz.gif', { :title => 'Linkliste ausblenden', :align => 'right' }), nil, :id => "open_taglist_link_#{dom_id}") do |page|
      page.visual_effect(:toggle_blind, "tag_link_list_#{dom_id}", :duration => 0.5)
    end
  end
  
  def open_window_js_code(url)
#     "window.open('#{url}','','height=800,width=800,scrollbars=yes,resizable=yes,dependent=yes');return false;"
#     "popup=window.open('#{url}','','height=800,width=800,scrollbars=yes,resizable=yes,dependent=yes');if (window.screenLeft != 'undefined') { popup.moveTo(window.screenLeft + 10, window.screenTop); };return false;"
    
#    "params='height=800,width=800,scrollbars=yes,resizable=yes,dependent=yes';" + \
#    "params='height='+(screen.height-100)+',width='+(screen.width-100)+',scrollbars=yes,resizable=yes,dependent=yes';" + \
    "params='scrollbars=yes,resizable=yes,dependent=yes,fullscreen=yes';" + \
    "if (navigator.appName == 'Microsoft Internet Explorer') { params += ',top=' + (window.screenTop + 10); params += ',left=' + (window.screenLeft + 10); };" + \
#    "if (navigator.appName == 'Microsoft Internet Explorer') { params += ',top=' + (window.screenTop); params += ',left=' + (window.screenLeft); };" + \
#     "alert(params);alert(window.screenTop);alert(window.screenLeft);" + \
    "window.open('#{url}','popup',params);return false;"
  end
  
  
  # def error_messages_for(object_name, options = {})
  #   options = options.symbolize_keys
  #   object = options[:object] || instance_variable_get("@#{object_name}")
  #   if object && !object.errors.empty?
  #     content_tag("div",
  #       content_tag(
  #       options[:header_tag] || "h2",
  #       "#{object.errors.count} Fehler verhindern, dass diese Daten gespeichert werden!"
  #       ) +
  #       content_tag("p", "Mit folgenden Feldern gab es Probleme:") +
  #       content_tag("ul", object.errors.collect { |attr, msg| content_tag(:li, msg) }), "id" => options[:id] || "errorExplanation", "class" => options[:class] || "errorExplanation" 
  #     )
  #   else
  #     ""
  #   end
  # end  
  
#  # Ersatz für error_messages_for
#  def german_error_messages_for(*params)
#    options = params.last.is_a?(Hash) ? params.pop.symbolize_keys : {}
#    objects = params.collect {|object_name| instance_variable_get("@#{object_name}") }.compact
#    count   = objects.inject(0) {|sum, object| sum + object.errors.count }
#    unless count.zero?
#      html = {}
#      [:id, :class].each do |key|
#      if options.include?(key)
#        value = options[key]
#          html[key] = value unless value.blank?
#        else
#          html[key] = 'errorExplanation'
#        end
#      end
#      header_message = "Beim Speichern sind #{count} Fehler aufgetreten!"
#      error_messages = objects.map {|object| object.errors.collect { |attr, msg| content_tag(:li, msg) } }
##       error_messages = objects.map {|object| object.errors.full_messages.map {|msg| content_tag(:li, msg) } }
#      content_tag(:div,
#        content_tag(options[:header_tag] || :h3, header_message) <<
#          content_tag(:p, 'In folgenden Feldern:') <<
#          content_tag(:ul, error_messages),
#        html
#      )
#    else
#      ''
#    end
#  end
end
