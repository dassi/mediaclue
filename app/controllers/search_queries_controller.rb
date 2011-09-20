class SearchQueriesController < ApplicationController
  
  protected #######################################################################################

  def find_search_query
    @search_query = SearchQuery.find(params[:id].to_i)
  end
  
  public ##########################################################################################

  def create
    SearchQuery.create(params[:search_query].merge(:user => current_user))
  end
  
  def destroy
    find_search_query
    permit :edit, @search_query do
      @search_query.destroy

      flash[:notice] = 'Suchanfrage gelöscht'
      redirect_to media_sets_url
    end
  end
  
  def toggle_notifications
    find_search_query
    permit :edit, @search_query do
      @search_query.toggle_notifications

      flash[:notice] = 'Suchanfrage geändert'
      redirect_to :back
    end
    
  end
  
end
