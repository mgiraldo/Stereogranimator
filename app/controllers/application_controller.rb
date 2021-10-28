class ApplicationController < ActionController::Base
  protect_from_forgery
  helper :all
  helper_method :current_user_session, :current_user
  before_action :ensure_domain, :check_flickr

  APP_DOMAIN = 'stereo.mauriciogiraldo.com'

  def logout_flickr
    killFlickrSession()
    redirect_to "/"
  end

  def get_flickr
    url = getFlickrToken()
    redirect_to url
  end

  def check_flickr
    @get_from_flickr = false

    @flickr_url = "/getflickr"

    # puts ">>>>>>  #{@get_from_flickr}  <<<<<<<<"

    # user overrides, doesnt want flickr
    # there is a cookie
    if cookies[:flickr_verifier] == nil || cookies[:flickr_verifier] == ""
      # are we returning from flickr?
      if params[:oauth_verifier]
        # yes
        if cookies[:flickr_token] != nil && cookies[:flickr_secret] != nil
          # gimme my access
          response = flickr.get_access_token(cookies[:flickr_token], cookies[:flickr_secret], params[:oauth_verifier])
          puts response
          # set flickr access info to user's info
          cookies[:flickr_username] = URI.unescape(response["username"])
          cookies[:flickr_token] = response["oauth_token"]
          cookies[:flickr_secret] = response["oauth_token_secret"]
          cookies[:flickr_verifier] = params[:oauth_verifier]
          @get_from_flickr = true
        # else
          # some error in cookies... get a new url
          # @flickr_url = getFlickrToken()
        end
      # else
        # user has not authenticated yet
        # @flickr_url = getFlickrToken()
      end
    else
      # there was a verified cookie...
      # puts ">>>>>>  #{cookies[:flickr_verifier]}  <<<<<<<<"
      @get_from_flickr = true
    end

    # puts ">>>>>>  #{@get_from_flickr}  <<<<<<<<"

    if params[:noflickr] != nil && params[:noflickr].to_i == 1
      @get_from_flickr = false
    end

    checkFlickrCookies()
  end

  def killFlickrSession
    cookies[:flickr_username] = nil
    cookies[:flickr_token] = nil
    cookies[:flickr_secret] = nil
    cookies[:flickr_verifier] = nil
  end

  def getFlickrToken
    callback_url = URI.escape("#{request.protocol}#{request.host_with_port}/create")
    token = flickr.get_request_token(:oauth_callback => callback_url)
    cookies[:flickr_token] = token['oauth_token']
    cookies[:flickr_secret] = token['oauth_token_secret']
    return flickr.get_authorize_url(token['oauth_token'], :perms => 'read', :oauth_callback => callback_url)
  end

  def checkFlickrCookies
    if cookies[:flickr_verifier] != nil && cookies[:flickr_token] != nil && cookies[:flickr_secret] != nil
      flickr.access_token = cookies[:flickr_token]
      flickr.access_secret = cookies[:flickr_secret]
    end
  end

  def ensure_domain
    if request.env['HTTP_HOST'] != APP_DOMAIN
      # HTTP 301 is a "permanent" redirect
      redirect_to "http://#{APP_DOMAIN}#{request.fullpath}", :status => 302 unless request.env['HTTP_HOST'] == 'localhost:3001' || request.env['HTTP_HOST'] == 'localhost:3000' || request.env['HTTP_HOST'] == 'stereomga.herokuapp.com'
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