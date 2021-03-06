ActionController::Routing::Routes.draw do |map|

  map.resources :media,
                :member => {:generate_previews => :get, :read_meta_data => :get, :report_misuse => [:get, :post]}
  map.resources :media_sets,
                :collection => {:browse => :get},
                :member => {:uploader => :get, :uploader_window => :get, :upload => :post,
                            :order => :get, :update_positions => :post,
                            :add_media => [:put, :post], :remove_media => [:put, :post], :move_media => [:post], :merge => :get,
                            :remove_all_media => :post}
  map.resources :public_slideshows, :as => 'galleries'
  
  map.resources :search_queries, :member => {:toggle_notifications => :post}

  
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => 'media_sets', :protocol => 'http://'
  map.search 'search', :controller => 'search', :action => 'index'
  map.search_result 'search/result', :controller => 'search', :action => 'result'

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
