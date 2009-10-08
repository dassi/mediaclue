class MediaController < ApplicationController
  
  protected #######################################################################################
  
  # Hilfsfunktion, die die Suche mit einer SearchQuery macht
  # TODO: Evt. auslagern?
  def search_with_query(search_query)
    
    if not search_query.ferret_query.blank?
      
      find_options = {}
      ferret_options = {:limit => MAX_SEARCH_RESULTS}
      
      if search_query.my_media_only?
        find_options[:conditions] = ['owner_id = ?', current_user.id]
      end
        
      media = Medium.find_with_ferret_for_user(search_query.ferret_query, current_user, ferret_options, find_options)
      media_from_sets = MediaSet.find_media_with_ferret_for_user(search_query.ferret_query, current_user, ferret_options, find_options)
      found_media = (media + media_from_sets).uniq
    else
      found_media = []
    end
    
    # Allenfalls nur bestimmte Medientypen berücksichtigen
    # TODO: Dies ist besser (oder zusätzlich) in find_with_ferret_for_user und find_media_with_ferret_for_user, siehe oben.
    # Es war aber nicht ganz trivial, auf den ersten Blick, deshalb hier an zentraler Stelle sichergestellt:
    if not search_query.all_media_types?
      klasses = search_query.media_types_classes

      # Filtern, falls nicht alle angewählt sind
      if Medium.sub_classes.to_set != klasses
        found_media.reject! { |m| not klasses.any? { |klass| m.instance_of?(klass) }}
      end
    end

    found_media
  end
  
  public ##########################################################################################
  
  # GET /media
  def index
    @query = current_user.last_search_query || current_user.build_last_search_query(:images => true, :audio_clips => true, :video_clips => true, :documents => true)
  end

  
  # GET /media/1
  # GET /media/1.png?size=medium
  # GET /media/1.gif?size=medium
  # GET /media/1.jpeg?size=medium
  # GET /media/1.jpg?size=medium
  def show    
    @medium = Medium.find params[:id]
    permit :view, @medium do
    # permit "owner of :medium or viewer of :medium" do
      if params[:format]
        params[:format].downcase!
  #      params[:size] ||= :small if @medium.is_a? Image
      end

      respond_to do |format|
        format.html { render :action => 'show' }

        # Formate aus MIME-Type des Mediums erzeugen (für Download wichtig. Bilder werden beim Anzeigen ansonsten direkt via public-URL angezeigt)
        @medium.class.file_extensions.each do |ext|
          format.send(ext) { send_file @medium.full_filename(params[:size]), :type => @medium.content_type, :disposition => 'attachment', :filename => @medium.pretty_filename }
        end
      end
    end
  end

  # GET /media/new
  # GET /media/new.xml
  def new
    @medium = Medium.new

    respond_to do |format|
      format.html # new.html.haml
    end
  end

  # GET /media/1/edit
  def edit
    @medium = Medium.find params[:id]
    permit :edit, @medium do
      @tag_string  = @medium.tag_names
      @user_groups = UserGroup.find :all    
    end
  end  

  # POST /media
  # POST /media.xml
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

  # PUT /media/1
  # PUT /media/1.xml
  def update
    @medium = Medium.find params[:id]
    permit :edit, @medium do
      if @medium
        medium_params = params[:media_set][:media_attributes][params[:id]]

        respond_to do |format|
          if @medium.update_attributes(medium_params)
            flash[:notice] = 'Medium wurde erfolgreich aktualisiert.'
            format.html { redirect_to medium_url(@medium) }
            # format.xml { head :ok }
          else
            @user_groups = UserGroup.find :all
            format.html { render :action => "edit" }
            # format.xml  { render :xml => @medium.errors, :status => :unprocessable_entity }
          end
        end
      end
    end
  end

  # DELETE /media/1
  # DELETE /media/1.xml
  def destroy
    @medium = Medium.find params[:id]
    permit :edit, @medium do
      @medium.destroy

      respond_to do |format|
        format.html { redirect_to media_sets_url }
      end
    end
  end

  # PUT /media_sets/1/media/1/add
  # Medium zu Set hinzufügen
  def add
    @media_set = MediaSet.find params[:media_set_id]
    @medium = Medium.find params[:id]
    permit :edit, @media_set do
      unless @media_set.images.include? @medium
        @media_set.images << @medium

        respond_to do |format|
          format.js do
            render :update do |page|
              page.insert_html :bottom, 'collected_media', :partial => "media/#{@medium.template_path}/collection_item", :object => @medium, :locals => {:media_set => @media_set}
            end
          end
        end
      else
        render :nothing => true
      end
    end
  end

  # PUT /media_sets/1/media/1/remove
  # Medium aus Set entfernen
  def remove
    @media_set = MediaSet.find params[:media_set_id]
    @medium = Medium.find params[:id]
#    permit "(owner of :media_set) and (owner of :medium or viewer of :medium)" do
    permit :edit, @media_set do
      collection_method = @medium.template_path

      if @media_set and !@media_set.owning? and @medium and @media_set.send(collection_method).include? @medium
        @media_set.send(collection_method).delete @medium

        respond_to do |format|
          format.js do
            render :update do |page|
              page.remove [params[:div_prefix], "medium_#{@medium.id}"].compact.join('_')
            end
          end
        end
      else
        render :nothing => true
      end
    end
  end

  

  # GET /media/search
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
    
      # Composing MediaSet des Users in Session merken
      session[:composing_media_set_id] = current_user.composing_media_set.id
        
      # Redirect zum aktuellen Suchresultat-MediaSet
      redirect_to media_set_url(media_set)
    else
      flash[:notice] = 'Keine Medien gefunden'
      redirect_to media_path
    end
  end

end
