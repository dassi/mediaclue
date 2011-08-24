class PublicSlideshowsController < ApplicationController

  MEDIA_SET_STYLES = ['lightbox', 'slideshow']
  
  skip_before_filter :login_required
  layout 'public_slideshow'
  
  public ##########################################################################################
  
  # Übersicht der Diashows
  def index
    @media_sets = MediaSet.published
  end

  def show
    @media_set = MediaSet.find(params[:id])

    permit :view, @media_set do
      @size = params[:size]

      @style = params[:style] || 'lightbox'
      raise 'Wrong view type' unless MEDIA_SET_STYLES.include?(@style)

      # layout = 'public_slideshow'
      
      case @style
      when 'slideshow'
          @media = @media_set.images_for_user_as_viewer(nil)
      when 'lightbox'
        @size ||= 'small'
        @media = @media_set.images_for_user_as_viewer(nil)
      end

      action = ['show', @style, @size].compact.join('_')

      respond_to do |format|
        format.html do
          render :action => action
        end
        format.xspf # Playlist for Slideshow
      end
    end
  end

end
