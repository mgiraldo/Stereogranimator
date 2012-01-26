class ApplicationController < ActionController::Base
  protect_from_forgery
  helper :all
  helper_method :current_user_session, :current_user
  before_filter :ensure_domain

  APP_DOMAIN = 'stereo.nypl.org'

  def ensure_domain
    if request.env['HTTP_HOST'] != APP_DOMAIN
      # HTTP 301 is a "permanent" redirect
      redirect_to "http://#{APP_DOMAIN}#{request.fullpath}", :status => 301 unless request.env['HTTP_HOST'] == 'stereostaging.heroku.com' || request.env['HTTP_HOST'] == 'localhost:3000'
    end
  end
  
  private
    def current_user_session
      return @current_user_session if defined?(@current_user_session)
      # session not defined
      if session[:last_create] == nil # adding image creation timestamp
        session[:last_create] = 0
      end
      @current_user_session = UserSession.find
    end
    
    def current_user
      return @current_user if defined?(@current_user)
      @current_user = current_user_session && current_user_session.record
    end
    
    def require_user
      unless current_user
        store_location
        flash[:notice] = "You must be logged in to access this page"
        redirect_to new_user_session_url
        return false
      end
    end

    def require_no_user
      if current_user
        store_location
        flash[:notice] = "You must be logged out to access this page"
        redirect_to account_url
        return false
      end
    end
    
    def set_regular_user
      session[:last_create] = 0 
    end
    
    def store_location
      session[:return_to] = request.url
    end
    
    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end
end