class MediaController < ApplicationController
  
#  permit ""
  
  # GET /media
  # GET /media.xml
  def index
    respond_to do |format|
      format.html  # { render :action => 'index' }
#      format.xml  { render :xml => @media }
    end
  end
  
  
  # GET /media/1
  # GET /media/1.png?size=medium
  # GET /media/1.gif?size=medium
  # GET /media/1.jpeg?size=medium
  # GET /media/1.jpg?size=medium
  def show    
    @medium = Medium.find params[:id]
    permit "owner of :medium or viewer of :medium" do
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
    permit "owner of :medium" do
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
    permit "owner of :medium" do
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
    permit "owner of :medium" do
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
    permit "(owner of :media_set) and (owner of :medium or viewer of :medium)" do
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
    permit "owner of :media_set" do
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

    if not params[:search_fulltext].blank?
      media = Medium.find_with_ferret_for_user(params[:search_fulltext], current_user)
      media_from_sets = MediaSet.find_media_with_ferret_for_user(params[:search_fulltext], current_user)
      found_media = (media + media_from_sets).uniq
    else
      found_media = []
    end
    
    # Allenfalls nur bestimmte Medientypen berücksichtigen
    # TODO: Dies ist besser (oder zusätzlich) in find_with_ferret_for_user und find_media_with_ferret_for_user, siehe oben.
    # Es war aber nicht ganz trivial, auf den ersten Blick, deshalb hier an zentraler Stelle sichergestellt:
    if params[:media_types] and params[:media_types].any?
      klasses = params[:media_types].collect(&:constantize).to_set

      # Filtern, falls nicht alle angewählt sind
      if Medium.sub_classes.to_set != klasses
        found_media.reject! { |m| not klasses.any? { |klass| m.instance_of?(klass) }}
      end
    end

    if found_media.any?
      # Gefundene Medien in das Suchresultat-Set abspeichern
      media_set = current_user.search_result_media_set
      media_set.collectables.clear
      media_set.collectables << found_media
    
      # Composing MediaSet des Users in Session merken
      session[:composing_media_set_id] = current_user.composing_media_set.id
        
      # Redirect zum aktuellen Suchresultat-MediaSet
      redirect_to media_set_url(media_set)
    else
      flash[:notice] = 'Keine Medien gefunden'
      render :action => 'index'
    end
  end

end
