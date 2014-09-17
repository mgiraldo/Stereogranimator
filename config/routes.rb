Stereo::Application.routes.draw do
  resources :users

  namespace :admin do resources :users end

  get "gallery/index"

  get "about/index"

  post "animations/chooseSearch"

  resources :users, :user_sessions

## for publiceye exhibit
  match 'create_pe', :to => 'animations#choose_publiceye'
  match 'create_pe/:keyword', :to => 'animations#chooseSearch_publiceye'
  match 'convert_pe/:did', :to => 'animations#new_publiceye'
  match 'share_pe/:id', :to => 'animations#share_publiceye'
## end publiceye

  # basic creation "workflow"
  match 'choose', :to => 'animations#choose', :as => "choose"
  match 'choose/:keyword', :to => 'animations#chooseSearch', :as => "chooseSearch"
  match 'create', :to => 'animations#choose', :as => "create"
  match 'convert/:did', :to => 'animations#new', :as => "convert"
  match 'share/:id', :to => 'animations#share', :as => "share"
  match 'view/:id', :to => 'gallery#view', :as => "gallery_view"

  # animation creation (ajax)
  match "/animations/createJson/:x1/:y1/:x2/:y2/:width/:height/:delay/:digitalid/:rotation/:mode/:creator", :to => 'animations#createJson', :as => "animation_rotation"
  match "/animations/createJson/:x1/:y1/:x2/:y2/:width/:height/:delay/:digitalid/:mode/:creator", :to => 'animations#createJson', :as => "animation_creator"
  match "/animations/createJson/*path" => "animations#createJson"
  match "/animations/createJson" => "animations#createJson"

  # general content stuff
  match 'about', :to => 'about#what', :as => "about"
  match 'about/animatedgif', :to => 'about#animatedgif', :as => "about_animatedgif"
  match 'about/stereoscopy', :to => 'about#stereoscopy', :as => "about_stereoscopy"
  match 'about/anaglyph', :to => 'about#anaglyph', :as => "about_anaglyph"
  match 'about/credits', :to => 'about#credits', :as => "about_credits"
  match 'about/flickr', :to => 'about#flickr', :as => "about_flickr"
  match 'about/collection', :to => 'about#collection', :as => "about_collection"
  match 'what', :to => 'about#what', :as => "about_what"

  # gallery
  match 'gallery', :to => 'gallery#index', :as => "gallery"
  match 'gallery/:type', :to => 'gallery#index', :as => "gallery_type"
  match 'gallery/:type/:page', :to => 'gallery#index', :as => "gallery_type_paged"
  match 'gallery/:type/:page.:format', :to => 'gallery#index', :as => "gallery_type_paged_formatted"

  # image pixel extraction
  match 'getimagedata/:digitalid', :to => 'images#getimagedata', :as => "getimagedata"
  match 'getimagedata/', :to => 'images#getimagedata', :as => "getimagedata_plain"
  match 'getpixels', :to => 'images#getpixels', :as => "getpixels"
  match 'getpixels/:digitalid', :to => 'images#getpixels', :as => "getpixels"
  match 's/v', :to => 'images#verifyPhoto'

  #test
  match 'test/', :to => 'images#test'

  # "session" stuff
  match 'login' => 'user_sessions#new', :as => :login
  match 'logout' => 'user_sessions#destroy', :as => :logout
  match 'dismissInstructions' => 'user_session#dismissInstructions', :as => :dismissInstructions
  match 'logoutflickr' => 'application#logout_flickr'
  match 'getflickr' => 'application#get_flickr'

  # delete animations
  match "/animations/:id/kill" => "animations#destroy"

  resources :animations

  root :to => 'about#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  #match ':controller(/:action(/:id(.:format)))'
end
