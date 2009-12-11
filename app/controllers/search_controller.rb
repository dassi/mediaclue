class SearchController < ApplicationController
  

  def index
    @query = current_user.last_search_query || current_user.build_last_search_query(:images => true, :audio_clips => true, :video_clips => true, :documents => true)
  end

  # Medien suchen nach Suchkriterien
  def result

    # Query erstellen, entweder von ID, oder von Such-Parametern
    if params[:query_id]
      query = current_user.search_queries.find(params[:query_id])
    else
      query = current_user.get_or_create_last_search_query
    
      query.ferret_query = params[:search_fulltext]

      query.images = params[:media_types][:images] == '1'
      query.audio_clips = params[:media_types][:audio_clips] == '1'
      query.video_clips = params[:media_types][:video_clips] == '1'
      query.documents = params[:media_types][:documents] == '1'
    
      query.my_media_only = params[:my_media_only] == '1'
      
      query.save!

      # Allenfalls als SearchQuery abspeichern
      if (params[:save_query] == '1') && (not params[:saved_query_name].blank?)
        new_query = query.dup
        # new_query.user = current_user
        new_query.name = params[:saved_query_name]
        new_query.save!
        
        flash[:notice] = 'Diese Suchabfrage wurde gespeichert.'
      end
    end


    # Suche durchführen
    # found_media = search_with_query(query)
    @search_result = query.execute
    
    if @search_result.empty?
      flash[:error] = 'Keine Medien gefunden'
      redirect_to search_path
    end
  end


  # Zeige per AJAX eine Liste der nächst-häufigsten Tags, zu den bereits eingetippten Tags
  def ajax_search_lookahead
    search_text = params[:tag_names]
    
    if not search_text.blank?
      search_tag_names = Medium.parse_tags(search_text)
      approx_total_hits = Medium.total_hits(search_text) + MediaSet.total_hits(search_text)
      
      # TODO: approx_total_hits muss zuverlässiger berechnet werden können, um aussagekräftig zu sein
      # Es bräuchte auch ein Rechte-Test, denn was nützen 100 gefundene Medien, welche danach nicht angezeigt werden dürfen?
    else
      search_tag_names = []
      approx_total_hits = nil
    end

    render :update do |page|
      page.replace_html 'related_tags', :partial => "most_related_tags", :locals => {:search_tag_names => search_tag_names}
      page.replace_html 'approx_total_hits', :partial => "approx_total_hits", :locals => {:approx_total_hits => approx_total_hits}
    end
    
  end
  
end
