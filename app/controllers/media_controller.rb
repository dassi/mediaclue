class MediaController < ApplicationController
  
  protected #######################################################################################
  
  # Hilfsfunktion, die die Suche mit einer SearchQuery macht
  # TODO: Evt. auslagern?
  def search_with_query(search_query)
    
    find_options = {}
    find_options[:conditions] = {}
    find_options[:limit] = MAX_SEARCH_RESULTS
    
    find_options[:conditions][:media] = {}
    
    if search_query.my_media_only?
      find_options[:conditions][:media][:owner_id] = current_user.id
    end

    if not search_query.all_media_types?
      klasses = search_query.media_types_classes.collect(&:to_s)

      # Filtern, falls nicht alle angewählt sind
      find_options[:conditions][:media][:type] = klasses
      
    end
    
    search_with_ferret = (not search_query.ferret_query.blank?)

    find_options_for_medium = find_options.dup
    find_options_for_medium[:conditions].delete(:media_sets)
    
    find_options_for_media_set = find_options.dup
    # find_options_for_media_set[:conditions].delete(:media)
    
    # Suche per ferret, oder direkt in der DB
    if search_with_ferret
      
      ferret_options = {:limit => MAX_SEARCH_RESULTS}
        
      media = Medium.find_with_ferret_for_user(search_query.ferret_query, current_user, ferret_options, find_options_for_medium)
      
      if not search_query.my_media_only?
        media_from_sets = MediaSet.find_media_with_ferret_for_user(search_query.ferret_query, current_user, ferret_options, find_options_for_media_set)
      else
        media_from_sets = []
      end
      
    else
      media = Medium.find_all_for_user(current_user, find_options_for_medium)

      if not search_query.my_media_only?
        media_from_sets = MediaSet.find_all_media_for_user(current_user, find_options_for_media_set)
      else
        media_from_sets = []
      end
      
    end

    # Suchresultat zusammenfassen
    found_media = (media + media_from_sets).uniq
    
    # # Allenfalls nur bestimmte Medientypen berücksichtigen
    # # TODO: Dies ist besser (oder zusätzlich) in find_with_ferret_for_user und find_media_with_ferret_for_user, siehe oben.
    # # Es war aber nicht ganz trivial, auf den ersten Blick, deshalb hier an zentraler Stelle sichergestellt:
    # if not search_query.all_media_types?
    #   klasses = search_query.media_types_classes
    # 
    #   # Filtern, falls nicht alle angewählt sind
    #   if Medium.sub_classes.to_set != klasses
    #     found_media.reject! { |m| not klasses.any? { |klass| m.instance_of?(klass) }}
    #   end
    # end

    found_media
  end
  
  public ##########################################################################################
  
  def index
    @query = current_user.last_search_query || current_user.build_last_search_query(:images => true, :audio_clips => true, :video_clips => true, :documents => true)
  end

  
  def show    
    @medium = Medium.find params[:id]
    permit :view, @medium do
      if params[:format]
        params[:format].downcase!
      end

      respond_to do |format|
        format.html { render :action => 'show' }

        # Formate aus MIME-Type des Mediums erzeugen (für Download wichtig. Bilder werden beim Anzeigen ansonsten direkt via public-URL angezeigt)
        @medium.class.file_extensions.each do |ext|
          format.send(ext) { send_file @medium.full_filename, :type => @medium.content_type, :disposition => 'attachment', :filename => @medium.pretty_filename }
        end
      end
    end
  end


  def new
    @medium = Medium.new

    respond_to do |format|
      format.html # new.html.haml
    end
  end


  def edit
    @medium = Medium.find params[:id]
    permit :edit, @medium do
      @tag_string  = @medium.tag_names
      @user_groups = UserGroup.find :all    
    end
  end  


  def create
    @medium = Medium.new params[:medium]

    respond_to do |format|
      if @medium.save
        flash[:notice] = 'Medium wurde erfolgreich erstellt.'
        format.html { redirect_to @medium }
      else
        @user_groups = UserGroup.find :all
        format.html { render :action => "new" }
      end
    end
  end  


  def update
    @medium = Medium.find params[:id]
    permit :edit, @medium do
      if @medium
        # Hinweis: Die Parameter kommen deshalb im Kontext eines media_sets, weil das Formular für ein Medium
        # generell auch als Teilformular eines MediaSets dienen muss.
        medium_params = params[:media_set][:media_attributes][params[:id]]

        respond_to do |format|
          if @medium.update_attributes(medium_params)
            flash[:notice] = 'Medium wurde erfolgreich aktualisiert.'
            format.html { redirect_to medium_url(@medium) }
          else
            @user_groups = UserGroup.find :all
            format.html { render :action => "edit" }
          end
        end
      end
    end
  end


  def destroy
    @medium = Medium.find params[:id]
    permit :edit, @medium do
      @medium.destroy

      respond_to do |format|
        format.html { redirect_to media_sets_url }
      end
    end
  end




  # Medien suchen nach Suchkriterien
  def search

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
        new_query.user = current_user
        new_query.name = params[:saved_query_name]
        new_query.save!
        
        flash[:notice] = 'Diese Suchabfrage wurde gespeichert.'
      end
    end


    # Suche durchführen
    found_media = search_with_query(query)
    
    if found_media.any?
      # Gefundene Medien in das Suchresultat-Set abspeichern
      media_set = current_user.search_result_media_set
      media_set.media_set_memberships.clear
      media_set.media << found_media
    
      # # Composing MediaSet des Users in Session merken
      # session[:composing_media_set_id] = current_user.composing_media_set.id
        
      # Redirect zum aktuellen Suchresultat-MediaSet
      redirect_to media_set_url(media_set)
    else
      flash[:notice] = 'Keine Medien gefunden'
      redirect_to media_path
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
      page.replace_html 'related_tags', :partial => "media/most_related_tags", :locals => {:search_tag_names => search_tag_names}
      page.replace_html 'approx_total_hits', :partial => "media/approx_total_hits", :locals => {:approx_total_hits => approx_total_hits}
    end
    
  end
  
  def generate_previews
    @medium = Medium.find params[:id]

    permit :edit, @medium do
      @medium.recreate_previews
      flash[:notice] = 'Vorschau-Varianten werden erzeugt. Dies kann bis zu einigen Minuten in Anspruch nehmen, bis die Vorschauen verfügbar sind.'
    end
    
    redirect_to :action => 'show'
  end
  
end
