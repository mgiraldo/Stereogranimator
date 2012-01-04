Stereo::Application.routes.draw do
  get "gallery/index"

  get "about/index"

  resources :animations
  
  match 'about', :to => 'about#what', :as => "about"
  match 'what', :to => 'about#what', :as => "about_what"
  match 'gallery', :to => 'gallery#index', :as => "gallery"
  match 'gallery/:type', :to => 'gallery#index', :as => "gallery_type"
  match 'gallery/:type/:page', :to => 'gallery#index', :as => "gallery_type_paged"
  match 'gallery/:type/:page.:format', :to => 'gallery#index', :as => "gallery_type_paged_formatted"
  match 'view/:id', :to => 'gallery#view', :as => "gallery_view"
  match 'choose', :to => 'animations#choose', :as => "choose"
  match 'create', :to => 'animations#choose', :as => "create"
  match 'convert/:did', :to => 'animations#new', :as => "convert"
  match 'share/:id', :to => 'animations#share', :as => "share"
  match 'getimagedata/:digitalid', :to => 'animations#getimagedata', :as => "getimagedata"
  match 'getimagedata/', :to => 'animations#getimagedata', :as => "getimagedata_plain"

  match "/animations/createJson/*path" => "animations#createJson"

  root :to => 'about#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  #match ':controller(/:action(/:id(.:format)))'
end
