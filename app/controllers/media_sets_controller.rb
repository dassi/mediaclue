class MediaSetsController < ApplicationController

  MEDIA_SET_STYLES = ['lightbox']
  
  protected #######################################################################################
  
  # Medien aus Set entfernen
  def remove_media_from_media_set(media_set, media)

    removed_media = []
    
    for medium in media
      if permit?(:view, medium)
        removed_media << medium
      end
    end

    media_set.media.delete(removed_media)
    
    removed_media
  end
  

  # Medium zu Set hinzufügen
  def add_media_to_media_set(media_set, media)

    added_media = []
    
      for medium in media
        if permit?(:view, medium) && (not media_set.media.include?(medium))
          added_media << medium
        end
      end
      
      media_set.media << added_media

      added_media
  end

  public ##########################################################################################
  
  # GET /media_sets
  # GET /media_sets.xml
  def index
    respond_to do |format|
      format.html
    end
  end

  # GET /media_sets/1
  # GET /media_sets/1.xml
  def show
    @media_set = MediaSet.find params[:id]

    permit :view, @media_set do
      session[:per_page] = params[:per_page] if params[:per_page]
      @per_page = session[:per_page] || 20
      if params[:style] == 'lightbox'
        @media = @media_set.images_for_user_as_viewer(current_user)
      else
        @media = @media_set.media_for_user_as_viewer(current_user)
      end

      # Allenfalls paginaten, sofern nicht alle angezeigt werden sollen
      unless @per_page == 'all'
        @media = @media.paginate :page => params[:page], :per_page => @per_page
        @paginate = true
      else
        @paginate = false
      end
      
      @size = params[:size] || 'small'
      @composing_media_set = current_user.composing_media_set

      render_block = nil    
      render_block = lambda {render :action => "show_#{params[:style]}"} if params[:style] and MEDIA_SET_STYLES.include?(params[:style])

      if @composing_media_set.nil? or (@composing_media_set and permit?(:edit, @composing_media_set)) 
        respond_to do |format|
          format.html(&render_block)
          format.zip  { send_file @media_set.to_zip_for_user(current_user), :type => 'application/zip', :disposition => 'attachment' }
          format.pdf  { send_file @media_set.to_pdf_for_user(current_user), :type => 'application/pdf', :disposition => 'attachment' }
        end
      end
    end
  end
  

  # GET /media_sets/1/edit
  def edit
    @media_set = MediaSet.find params[:id]
    permit :edit, @media_set do
      @media_set.define! unless @media_set.media.empty?
      @media = @media_set.media_for_user_as_owner(current_user)
      @user_groups = UserGroup.find :all
    end
  end

  # POST /media_sets
  # POST /media_sets.xml
  def create
    @media_set = MediaSet.new(params[:media_set])
    
    respond_to do |format|
      if @media_set.save
        flash[:notice] = 'Kollektion erfolgreich erstellt.'
        format.html { redirect_to(@media_set) }
      else
        @user_groups = UserGroup.find :all
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /media_sets/1
  # PUT /media_sets/1.xml
  def update
    @media_set = MediaSet.find params[:id]
    if params['cancel']
      redirect_to(@media_set) 
      return
    end

    @media = @media_set.media_for_user_as_owner(current_user)
    
    permit :edit, @media_set do
      respond_to do |format|
        
        # "vererbe" einige am media_set formular setzbare Parameter an die anhängigen Medien 
        params = inherit_media_params_from_media_set
        
        # mass assignment von media_set parametern enthält nested parameter media_attributes zum update der 
        # in media enthaltenen medien. Dies geschieht z.Zt. _ohne_ Prüfung von permissions, da attacks unwahrscheinlich sind !
        # TODO: Ebendiese Rechte prüfen!
        if @media_set.update_attributes(params[:media_set])
          # Dem Medienset neu den Status "defined" verleihen
          @media_set.store! unless @media_set.defined?
          flash[:notice] = 'Kollektion erfolgreich gespeichert.'
          format.html { 
            redirect_to(@media_set) 
          }
        else
          @user_groups = UserGroup.find :all
          format.html { 
            render :action => 'edit'
          }
        end
      end
    end
  end

  # DELETE /media_sets/1
  # DELETE /media_sets/1.xml
  def destroy
    @media_set = MediaSet.find params[:id]
    permit :edit, @media_set do
      @media_set.destroy

      respond_to do |format|
        format.html { redirect_to(media_sets_url) }
  #       format.xml  { head :ok }
      end
    end
  end

  # GET /media_sets/1/uploader
  # Lädt den Uploader im Browser und bereitet ihn für den Upload von Medien in ein bestimmtes Set vor
  def uploader
    @media_set = MediaSet.find(params[:id])
    permit :edit, @media_set do
      @allowed_upload_extensions = Medium.all_media_file_extensions
      @authenticity_token = form_authenticity_token
    end
  end
  
  
  # POST /media_sets/1/upload
  # POST /media_sets/1/upload.xml
  # POST /media_sets/1/upload.js
  # Medium aus Uploader in ein bestimmtes Set heraufladen
  def upload    
    @media_set = MediaSet.find(params[:id])
    
    # Sicherheitsabfrage: Nur der Besitzer des MediaSets kann darin hochladen
    permit :edit, @media_set do
      uploaded_file = params[:medium][:uploaded_data]
      
      # Falls MIME-Typ nicht durch JumpLoader schon gesetzt wurde, dann diesen serverseitig herausfinden und setzen
      if uploaded_file.content_type == 'content/unknown'
        mime_types = MIME::Types.type_for(uploaded_file.original_filename)

        if mime_types.empty?
          # Wir probieren es via file-Befehl auf der Shell
          if uploaded_file.is_a?(Tempfile) # Könnte auch StringIO sein
            # TODO: Plattform-Unabhägigkeit?!
            mime_type = `file --brief --mime #{uploaded_file.path}`.strip
            uploaded_file.content_type = mime_type
            logger.info "MIME-Typ detektiert durch file-Befehl: #{uploaded_file.content_type}"
          end
        else
          uploaded_file.content_type = mime_types.first.content_type 
          logger.info "MIME-Typ detektiert durch mime-types gem: #{uploaded_file.content_type}"
        end

        # Evt. auch mit gem http://ruby-filemagic.rubyforge.org/, welches aber eine compilierung benötigt, mit Abhängigkeiten,
        # die auf Servern evt. nicht gegeben ist.
      else
        logger.info "MIME-Typ detektiert durch Webserver: #{uploaded_file.content_type}"
      end

      # Medium-Klasse anhand des MIME-Typs der hochgeladenen Datei ausfindig machen
      # OPTIMIZE: Refactoring in eine Factory-Methode von Medium, z.B. Medium.create_by_mime_type(mime_type, *create_args)
      medium_class = Medium.class_by_content_type(uploaded_file.content_type)
      if medium_class
        # mit der Option "urlEncodeParameters => true" des Jumploaders wird der Filename urlencoded gesendet, 
        # damit werden Probleme mit der UTF-Codierung umgangen (Umlaute werden zu "\357\277\275", dem "lost in translation"-Zeichen von UTF-8).
        # Daher muss des Filename wieder urldecoded werden
        filename = CGI.unescape uploaded_file.original_filename

        # TODO: Mass-assignment Sicherheitsloch prüfen! Mit attr_protected oder ähnlich
        @medium = medium_class.new
        @medium.is_importing_metadata = (params[:importMetadata] == '1')
        @medium.attributes = params[:medium].merge(:name => filename, :original_filename => filename)

        # Medium dem aktuellen User in der Rolle "owner" hinzufügen
        @medium.owner = current_user

        # Speichern
        @medium.save!
        
        # TODO: Exceptions oder Fehler beim Uploaden an JumpLoader melden, ober per Ajax einblenden.

        # Medium dem MediaSet hinzufügen
        @media_set.media << @medium

        # Das Medium dem owner media set des users zuordnen
        # TODO: Das hier alleine reicht nicht aus auf die Dauer. Was passiert mit Medien deren Owner verändert wird? Etc. Hier braucht es ein
        # besseres Konzept, wie man die Kollektion "Meine Medien" immer auf dem neusten Stand halten kann
        current_user.owner_media_set.media << @medium
      else
        logger.error "Keine Medium Klasse gefunden für content_type '#{uploaded_file.content_type}'!"
        render :nothing => true, :status => :bad_request
        return
      end


      respond_to do |format|
  #       format.html { redirect_to(media_sets_url) }
        format.js   # upload.rjs
      end      
    end
  end
  
  
  def set_collection
    @media_set = MediaSet.find params[:id]
    permit :edit, @media_set do
      # Wenn leer, dann löschen, sonst zurücksetzen auf "defined"
      if current_user.composing_media_set.media.empty?
        current_user.composing_media_set.destroy
      else
        current_user.composing_media_set.define! 
      end
      @media_set.compose!
    end   
    
    # # Composing MediaSet des Users in Session merken
    # session[:composing_media_set_id] = current_user.composing_media_set.id
        
    # Redirect zum aktuellen Suchresultat-MediaSet
    redirect_to media_set_url(@media_set)
  end
  

  # GET /media_sets/1/compose
  # Bereitet das hinzufügen von Medien aus einen bestimmten Set in das Composing Set vor
  def compose
    @title = 'Neue Kollektion zusammenstellen'
    @media_set = MediaSet.find params[:id]
    permit :edit, @media_set do
      @media = @media_set.images
    end
  end
  
  
  def order
    @media_set = MediaSet.find params[:id]
    permit :edit, @media_set do
      if params[:style] == 'lightbox'
        @media = @media_set.images_for_user_as_viewer(current_user)
      else
        @media = @media_set.media_for_user_as_viewer(current_user)
      end
      @enable_ordering = true
      
      action = params[:style] ? "show_#{params[:style]}" : 'show'
      @size = params[:size]

      respond_to do |format|
#        format.html(&render_block)
        format.html { render :action => action }
      end  
    end
  end
    
  
  def update_positions
    @media_set = MediaSet.find params[:id]
    permit :edit, @media_set do
      params[:media_list].each_with_index do |id, position|     
        membership = @media_set.media_set_memberships.find_by_medium_id(id)
        membership.position = position
        membership.save!
        # möglich wäre direkt auch dies, aber JavaScript sendet für jedes Element einen Wert. membership.insert_at(position+1)
      end
      render :nothing => true
    end
  end
  

  # Medium zu Set hinzufügen
  def add_media
    media_set = MediaSet.find(params[:id])
    media = Medium.find(params[:selected_media] || params[:medium_id]).to_a
    
    if permit?(:edit, media_set)
      added_media = add_media_to_media_set(media_set, media)

      # OPTIMIZE: Unschön, dass hier die JS-Repsonse mit der Funktion "Zu Sammelkollektion" fix verbunden ist. Man kann eben auch in andere MediaSet adden.
      respond_to do |format|
        format.js do
          render :update do |page|
            for medium in added_media
              page.insert_html :bottom, 'collected_media', :partial => "media/#{medium.template_path}/collection_item", :object => medium, :locals => {:media_set => media_set}
            end
          end
        end
      end
    else
      render :nothing => true
    end
  end


  # Medien aus Set entfernen
  def remove_media
    media_set = MediaSet.find params[:id]
    media = Medium.find(params[:selected_media] || params[:medium_id]).to_a

    if media_set && media.any? && permit?(:edit, media_set)

      removed_media = remove_media_from_media_set(media_set, media)
      
      respond_to do |format|
        format.html do
          redirect_to media_set_path(media_set)
        end
        
        format.js do
          render :update do |page|
            for medium in removed_media
              page.remove [params[:div_prefix], "medium_#{medium.id}"].compact.join('_')
            end
          end
        end
      end
    else
      render :nothing => true
    end
  end
  
  # Medien aus Set entfernen
  def move_media
    source_media_set = MediaSet.find(params[:id])
    target_media_set = MediaSet.find(params[:target_media_set_id])
    media = Medium.find(params[:selected_media] || params[:medium_id]).to_a
    

    if target_media_set && source_media_set && media.any? && permit?(:edit, target_media_set) && permit?(:edit, source_media_set)

      removed_media = remove_media_from_media_set(source_media_set, media)
      added_media = add_media_to_media_set(target_media_set, removed_media)

      respond_to do |format|
        format.js do
          render :update do |page|
            for medium in removed_media
              page.remove [params[:div_prefix], "medium_#{medium.id}"].compact.join('_')
            end
            for medium in added_media
              page.insert_html :bottom, 'collected_media', :partial => "media/#{medium.template_path}/collection_item", :object => medium, :locals => {:media_set => target_media_set}
            end
          end
        end
      end
    else
      render :nothing => true
    end
  end
  

  # Mergen mit einer anderen Kollektion
  def merge
    target_media_set = MediaSet.find(params[:id])
    source_media_set = MediaSet.find(params[:source_media_set_id])

    if target_media_set && source_media_set && permit?(:edit, target_media_set) && permit?(:view, source_media_set)

      media = source_media_set.media_for_user_as_viewer(current_user)
      added_media = add_media_to_media_set(target_media_set, media)
      
      # TODO: Allenfalls auch Metadaten mergen

      respond_to do |format|
        format.html do
          flash[:notice] = 'Kollektionen verschmelzt. Ergebnis-Menge ist in dieser Kollektion.'
          redirect_to media_set_path(target_media_set)
        end
      end
    else
      render :nothing => true
    end
    
  end

  
  private #####################################################################
  
  def inherit_media_params_from_media_set
    return {} if params.nil?

    media_set_params = params[:media_set]
    return params if media_set_params.blank?

    # pseudo-Attribute für Vererbung müssen aus params entfernt werden, auch wenn keine Medien im Set,
    # da keine setter-Methode im MediaSet-Model vorhanden
    media_set_source  = media_set_params.delete(:source)
    media_set_viewers = media_set_params.delete(:viewers)

    media_attributes = media_set_params[:media_attributes]
    return params if media_attributes.blank?
    
    # echtes Attribut für Vererbung muss nicht aus params entfernt werden, da media_set auch tags hat
    media_set_tag_names = media_set_params[:tag_names]

    media_attributes.each do |k, m| 
      m[:source] = media_set_source if not media_set_source.blank?
      m[:viewers] = media_set_viewers if not media_set_viewers.blank?
                                               
      if not media_set_tag_names.blank?
        case params[:inherit_tags]
        when 'none'
          # nichts weiter tun
        when 'subjects'
          SUBJECT_SELECTIONS.each do |subject|
            if subject.include?(' ')
              tag_name = '"' + subject + '"'
            else
              tag_name = subject
            end
            m[:tag_names] << (' ' + tag_name) if media_set_tag_names.include?(tag_name)
          end
          
        when 'all'
          m[:tag_names] << (' ' + media_set_tag_names)
        end
      end
      
    end
    
    return params
  end

end
