module MediaSetsHelper
  
  def per_page_select(media_set, per_page, params = [])
    params_string = params.collect{|k,v| "#{k}=#{v}&"}
    select = select_tag :per_page, options_for_select(['5', '10', '15', '20', '25', '30', '50', '100', ['Alle', 'all']], per_page.to_s), 
                        :onchange => "location='#{media_set_path(media_set)}?#{params_string}per_page='+$('per_page').value"
                      
    "Medien pro Seite: #{select}"
  end

end
