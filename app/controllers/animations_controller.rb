class AnimationsController < ApplicationController
  before_filter :load
  
  def load
    @animations = Animation.all
    @animation = Animation.new
  end
  
  # GET /animations
  # GET /animations.json
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @animations }
    end
  end

  # GET /animations/1
  # GET /animations/1.json
  def show
    @animation = Animation.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @animation }
    end
  end

  # GET /animations/new
  # GET /animations/new.json
  def new
    respond_to do |format|
      format.html { render :layout => "new_rich"} # new.html.erb
      format.json { render :json => @animation }
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

  # GET /animations/createJson/:x1/:y1/:x2/:y2/:width/:height/:delay(cs)/:digitalid/:creator
  def createJson
    ##
    ##
    ##
    ## MUST VALIDATE THIS THING!!!!!
    ##
    ##
    ##
    
    # get parameters from url
    
    arr = params[:path].split('/')
    @animation = Animation.new()
    @animation.x1 = arr[0]
    @animation.y1 = arr[1]
    @animation.x2 = arr[2]
    @animation.y2 = arr[3]
    @animation.width = arr[4]
    @animation.height = arr[5]
    @animation.delay = arr[6]
    @animation.digitalid = arr[7]
    @animation.creator = arr[8]
    
    # future filename
    @animation.filename = Digest::SHA1.hexdigest('nyplsalt' + Time.now.to_s)
    
    # do some image magick
    im = Magick::Image.read(@animation.url).first
    
    fr1 = im.crop(@animation.x1,@animation.y1,@animation.width,@animation.height,true)
    fr2 = im.crop(@animation.x2,@animation.y2,@animation.width,@animation.height,true)
    
    list = Magick::ImageList.new
    list << fr1
    list << fr2
    list.delay = @animation.delay
    list.iterations = 0
    
    # gotta packet the file
    #anim = Magick::Image.new(@animation.width, @animation.height)
    #anim.format = "GIF"
    list.write("#{Rails.root}/tmp/#{@animation.filename}.gif")
    
    # upload to Amazon S3
    s3 = AWS::S3.new
    bucket = s3.buckets['stereogranimator']
    obj = bucket.objects[@animation.filename]
    obj.write(:file => "#{Rails.root}/tmp/#{@animation.filename}.gif")#(:single_request => true, :content_type  => 'image/gif', :data => anim)
    #list.write("#{Rails.public_path}/images/" + @animation.filename)
    
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
      format.html { redirect_to animations_url }
      format.json { head :ok }
    end
  end
end
