class SearchQueriesController < ApplicationController
  
  def create
    SearchQuery.create(params[:search_query].merge(:user => current_user))
  end
  
  def destroy
    @search_query = SearchQuery.find(params[:id].to_i)
    permit :edit, @search_query do
      @search_query.destroy

      respond_to do |format|
        format.html do
          flash[:notice] = 'Suchanfrage gelöscht'
          redirect_to media_sets_url
        end
      end
    end
  end
  
end
