Stereo::Application.routes.draw do
  resources :users

  namespace :admin do resources :users end

  get "gallery/index"

  get "about/index"

  post "animations/chooseSearch"

  resources :users, :user_sessions
  
  get 'login' => 'user_sessions#new', :as => :login
  get 'logout' => 'user_sessions#destroy', :as => :logout
  get 'dismissInstructions' => 'user_session#dismissInstructions', :as => :dismissInstructions
  
  get 'about', :to => 'about#what', :as => "about"
  get 'about/animatedgif', :to => 'about#animatedgif', :as => "about_animatedgif"
  get 'about/stereoscopy', :to => 'about#stereoscopy', :as => "about_stereoscopy"
  get 'about/anaglyph', :to => 'about#anaglyph', :as => "about_anaglyph"
  get 'about/credits', :to => 'about#credits', :as => "about_credits"
  get 'about/flickr', :to => 'about#flickr', :as => "about_flickr"
  get 'about/collection', :to => 'about#collection', :as => "about_collection"
  get 'what', :to => 'about#what', :as => "about_what"
  get 'gallery', :to => 'gallery#index', :as => "gallery"
  get 'gallery/:type', :to => 'gallery#index', :as => "gallery_type"
  get 'gallery/:type/:page', :to => 'gallery#index', :as => "gallery_type_paged"
  get 'gallery/:type/:page.:format', :to => 'gallery#index', :as => "gallery_type_paged_formatted"
  get 'view/:id', :to => 'gallery#view', :as => "gallery_view"
  get 'choose', :to => 'animations#choose', :as => "choose"
  get 'choose/:keyword', :to => 'animations#chooseSearch', :as => "chooseSearch"
  get 'create', :to => 'animations#choose', :as => "create"
  get 'convert/:did', :to => 'animations#new', :as => "convert"
  get 'share/:id', :to => 'animations#share', :as => "share"
  
  get 'getimagedata/:digitalid', :to => 'images#getimagedata', :as => "getimagedata"
  get 'getimagedata/', :to => 'images#getimagedata', :as => "getimagedata_plain"
  get 'getpixels', :to => 'images#getpixels'
  get 'getpixels/:digitalid', :to => 'images#getpixels'
  get 's/v', :to => 'images#verifyPhoto'
  #test
  get 'test/', :to => 'images#test'

  get 'logoutflickr' => 'application#logout_flickr'
  get 'getflickr' => 'application#get_flickr'

  get "/animations/createJson/:x1/:y1/:x2/:y2/:width/:height/:delay/:digitalid/:rotation/:mode/:creator", :to => 'animations#createJson', :as => "animation_rotation"
  
  get "/animations/createJson/:x1/:y1/:x2/:y2/:width/:height/:delay/:digitalid/:mode/:creator", :to => 'animations#createJson', :as => "animation_creator"

  get "/animations/createJson/*path" => "animations#createJson"
  
  get "/animations/createJson" => "animations#createJson"

  get "/animations/:id/kill" => "animations#destroy"

  resources :animations

  root :to => 'about#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  #match ':controller(/:action(/:id(.:format)))'
end
