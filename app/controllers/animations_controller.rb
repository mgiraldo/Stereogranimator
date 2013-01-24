class AnimationsController < ApplicationController
  before_filter :require_user, :only => [:index, :edit, :destroy]
  
  # GET /choose
  def choose
    callback_url = URI.escape(request.protocol + request.host_with_port + "/choose")

    @get_from_flickr = false

    @flickr_url = "?noflickr=1"

    # user overrides, doesnt want flickr
    # there is a cookie
    if cookies[:flickr_verifier] == nil
      # are we returning from flickr?
      if params[:oauth_verifier]
        # yes
        if cookies[:flickr_token] != nil && cookies[:flickr_secret] != nil
          # gimme my access
          response = flickr.get_access_token(cookies[:flickr_token], cookies[:flickr_secret], params[:oauth_verifier])
          # set flickr access info to user's info
          cookies[:flickr_username] = URI.unescape(response["username"])
          cookies[:flickr_token] = response["oauth_token"]
          cookies[:flickr_secret] = response["oauth_token_secret"]
          cookies[:flickr_verifier] = params[:oauth_verifier]
          @get_from_flickr = true
        else
          # some error in cookies... get a new url
          @flickr_url = getFlickrToken()
        end
      else
        # user has not authenticated yet
        @flickr_url = getFlickrToken()
      end
    else
      # there was a verified cookie...
      @get_from_flickr = true
    end

    if params[:noflickr] != nil && params[:noflickr].to_i == 1
      @flickr_url = "?noflickr=0"
      @get_from_flickr = false
    end

    checkFlickrCookies()
    
    @images = Image.randomSet(@get_from_flickr)
    respond_to do |format|
      format.html
    end
  end

  def getFlickrToken
    callback_url = URI.escape(request.protocol + request.host_with_port + "/choose")
    token = flickr.get_request_token(:oauth_callback => callback_url)
    cookies[:flickr_token] = token['oauth_token']
    cookies[:flickr_secret] = token['oauth_token_secret']
    return flickr.get_authorize_url(token['oauth_token'], :perms => 'delete', :oauth_callback => callback_url)
  end

  def checkFlickrCookies
    if cookies[:flickr_verifier] != nil && cookies[:flickr_token] != nil && cookies[:flickr_secret] != nil
      flickr.access_token = cookies[:flickr_token]
      flickr.access_secret = cookies[:flickr_secret]
    end
  end
  
  def chooseSearch
    xid = 1
    checkFlickrCookies()
    xid = -1 if cookies[:flickr_secret] != nil
    @images = Image.findByKeyword(params[:keyword], xid)
    respond_to do |format|
      #format.html { render :json => @images }
      format.json { render :json => @images }
    end
  end
  
  # GET /animations
  # GET /animations.json
  def index
    @animations = Animation.order("id DESC")
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @animations }
    end
  end

  def share
    @animation = Animation.find(params[:id])
  
    respond_to do |format|
      format.html # show.html.erb
    end
  end
  
  # GET /animations/1
  # GET /animations/1.json
  def show
    @animation = Animation.find(params[:id])
    respond_to do |format|
      format.html { redirect_to "/view/#{@animation.id}" }
      format.json { render :json => @animation }
      format.png { redirect_to @animation.aws_url }
      format.jpeg { redirect_to @animation.aws_url }
      format.gif { redirect_to @animation.aws_url }
    end
  end

  # GET /animations/new
  # GET /animations/new.json
  def new
    checkFlickrCookies()
    @metadata = Image.getMetadata(params[:did])
    params[:xid] = params[:xid]==nil ? 0 : params[:xid].to_i
    if params[:xid]!=0
      photoinfo = Image.flickrDataForPhoto(params[:did])
      externalinfo = Image.externalData(params[:xid])
      if params[:xid] == -1
        # personal set
        @metadata = {"title"=>photoinfo[:info]["title"],"link"=>photoinfo[:info]["urls"][0]["_content"],"owner"=>photoinfo[:info]["owner"]["username"],"homeurl"=>"http://www.flickr.com/user/" + photoinfo[:info]["owner"]["nsid"]}
      else
        # bpl set
        @metadata = {"title"=>photoinfo[:info]["title"],"link"=>photoinfo[:info]["urls"][0]["_content"],"owner"=>externalinfo[:name],"homeurl"=>externalinfo[:homeurl]}
      end
    end
    if params[:xid].to_i == -1 && (cookies[:flickr_verifier] == nil || cookies[:flickr_token] == nil || cookies[:flickr_secret] == nil)
      redirect_to "/"
    else
      respond_to do |format|
        format.html # new.html.erb
      end
    end
  end

  # GET /animations/1/edit
  def edit
    @animation = Animation.find(params[:id])
  end

  # POST /animations
  # POST /animations.json
  def create
    @animation = Animation.new(params[:animation])

    respond_to do |format|
      if @animation.save
        format.html { redirect_to @animation, :notice => 'Animation was successfully created.' }
        format.json { render :json => @animation, :status => :created, :location => @animation }
      else
        format.html { render :action => "new" }
        format.json { render :json => @animation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # GET /animations/createJson/:x1/:y1/:x2/:y2/:width/:height/:delay(cs)/:digitalid/:mode/:creator
  def createJson

    current = Time.now.to_i
    if session[:last_create] == nil || current - session[:last_create] < 5 # can only create one every 10 seconds
     respond_to do |f|
       f.json { render :json => {:message => "Too many requests"}.to_json, :status => 429 }
     end
     return
    end
    # update session image creation timestamp
    session[:last_create] = current
    # get parameters from url
    
    @animation = Animation.new()
    
    @animation.x1 = params[:x1].to_i
    @animation.y1 = params[:y1].to_i
    @animation.x2 = params[:x2].to_i
    @animation.y2 = params[:y2].to_i
    @animation.width = params[:width].to_i
    @animation.height = params[:height].to_i
    @animation.delay = params[:delay].to_i
    @animation.digitalid = params[:digitalid]
    @animation.mode = params[:mode]
    @animation.creator = params[:creator]
    @animation.rotation = params[:rotation] != nil ? params[:rotation] : ""
    @animation.external_id = params[:xid] != nil ? params[:xid] : 0
    @animation.views = 0
    
    # get metadata
    meta = ""
    checkFlickrCookies()
    if @animation.external_id!=0
      external_photo = Image.flickrDataForPhoto(params[:digitalid])
      meta = external_photo[:info]["title"]
    else
      @im = Image.where("upper(digitalid) = ?", params[:digitalid].upcase).first
      if @im != nil
        meta = @im.meta
        if @im.converted == 0
          @im.converted = 1
          @im.save
        end
      end
    end
    @animation.metadata = meta
    #####
    respond_to do |format|
      if @animation.save
        format.html { render :nothing => true }
        format.json { render :json => @animation, :status => :created, :location => @animation }
      else
        format.html { render :nothing => true }
        format.json { render :json => @animation.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # PUT /animations/1
  # PUT /animations/1.json
  def update
    @animation = Animation.find(params[:id])

    respond_to do |format|
      if @animation.update_attributes(params[:animation])
        format.html { redirect_to @animation, :notice => 'Animation was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @animation.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # DELETE /animations/1
  # DELETE /animations/1.json
  def destroy
    @animation = Animation.find(params[:id])
    @animation.destroy

    respond_to do |format|
      format.html { redirect_to gallery_url }
      format.json { head :ok }
    end
  end
end
