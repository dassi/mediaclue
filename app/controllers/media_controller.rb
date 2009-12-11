class MediaController < ApplicationController
  
  protected #######################################################################################
  
  
  public ##########################################################################################
  
  def show    
    @medium = Medium.find(params[:id])
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
  end


  def edit(medium = nil)
    @medium = medium || Medium.find(params[:id])
    permit :edit, @medium do
      # Explizit render, weil wir auch von update hierher kommen
      render :action => "edit"
    end
  end  


  def create
    @medium = Medium.new params[:medium]

    if @medium.save
      flash[:notice] = 'Medium wurde erfolgreich erstellt.'
      redirect_to(@medium)
    else
      render(:action => "new")
    end
  end  


  def update
    @medium = Medium.find(params[:id])
    permit :edit, @medium do
      if @medium
        # Hinweis: Die Parameter kommen deshalb im Kontext eines media_sets, weil das Formular für ein Medium
        # generell auch als Teilformular eines MediaSets dienen muss.
        medium_params = params[:media_set][:media_attributes][params[:id]]

        if @medium.update_attributes(medium_params)
          flash[:notice] = 'Medium wurde erfolgreich aktualisiert.'
          if params[:back_url].present?
            redirect_to params[:back_url]
          else
            redirect_to medium_url(@medium)
          end
        else
          edit(@medium)
        end
      end
    end
  end


  def destroy
    @medium = Medium.find(params[:id])
    permit :edit, @medium do
      @medium.destroy

      flash[:notice] = 'Medium gelöscht'
      redirect_to media_sets_url
    end
  end

  
  def generate_previews
    @medium = Medium.find(params[:id])

    permit :edit, @medium do
      @medium.recreate_previews
      flash[:notice] = 'Vorschau-Varianten werden erzeugt. Dies kann bis zu einigen Minuten in Anspruch nehmen, bis die Vorschauen verfügbar sind.'
    end
    
    redirect_to :action => 'show'
  end
  
  def read_meta_data
    @medium = Medium.find(params[:id])
    @medium.reread_meta_data
    flash[:notice] = 'Metadaten eingelesen'
    redirect_to :action => 'show'
  end
  
end
