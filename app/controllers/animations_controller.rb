class AnimationsController < ApplicationController
  before_filter :require_user, :only => [:index, :edit, :destroy]
  
  # GET /choose/nyplid
  def choose
    @images = Animation.randomSet()
    respond_to do |format|
      format.html { render :layout => "new_rich"}
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
      format.jpeg { redirect_to @animation.aws_url }
      format.gif { redirect_to @animation.aws_url }
    end
  end

  # GET /animations/new
  # GET /animations/new.json
  def new
    @metadata = Image.getMetadata(params[:did])
    respond_to do |format|
      format.html { render :layout => "new_rich"} # new.html.erb
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
    if session[:last_create] == nil || current - session[:last_create] < 10 # can only create one every 10 seconds
      respond_to do |f|
        f.json { render :json => {:message => "Too many requests"}.to_json, :status => 429 }
      end
      return
    end
    # update session image creation timestamp
    session[:last_create] = current
    # get parameters from url
    
    @animation = Animation.new()
    
    @animation.x1 = params[:x1]
    @animation.y1 = params[:y1]
    @animation.x2 = params[:x2]
    @animation.y2 = params[:y2]
    @animation.width = params[:width]
    @animation.height = params[:height]
    @animation.delay = params[:delay].to_i
    @animation.digitalid = params[:digitalid]
    @animation.mode = params[:mode]
    @animation.creator = params[:creator]
          
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
    @derivatives = Animation.where("digitalid = ? ", @animation[:digitalid])
    if @derivatives.length == 0
      # no derivatives for this original image
      @im = Image.where(:digitalid => @animation.digitalid).first
      if @im != nil
        @im.converted = 0
        @im.save
      end
    end
    
    # delete from Amazon S3
    if @animation.filename != nil && @animation.filename != ""
      s3 = AWS::S3.new
      bucket = s3.buckets['stereogranimator']
      obj = bucket.objects[@animation.filename]
      obj.delete()
      obj = bucket.objects["t_" + @animation.filename]
      obj.delete()
    end
    
    @animation.destroy

    respond_to do |format|
      format.html { redirect_to gallery_url }
      format.json { head :ok }
    end
  end
end
