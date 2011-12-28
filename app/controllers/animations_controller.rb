class AnimationsController < ApplicationController
  before_filter :load
  
  def load
    @animations = Animation.all
    @animation = Animation.new
  end
  
  # GET /choose/nyplid
  def choose
    # TODO: request random list
    # TODO: consider error cases (feed not available)
    total_images = 43088 # as of 27/12/2011
    count = 9 # images to retrieve
    range = total_images - count
    first = rand(range)
    @feed = Feedzirra::Feed.fetch_and_parse("http://digitalgallery.nypl.org/feeds/dev/atom/?word=stereog*&imgs=120&num=#{first}")
    all =Array.new
    @feed.entries.each do |e|
      # images are id'd as tag:digitalgallery.nypl.org,2006:/nypldigital/id?G89F339_010F
      full_id = e.id
      tag = full_id.split('?')[1]
      all.push(tag)
    end
    images = all.sort_by{rand}[0..8]
    @images = Array.new(9)
    images.each_with_index do |image,i|
      @images[i] = {'tag' => image, 'src' => "http://images.nypl.org/index.php?id=#{image}&t=r"}
    end
    respond_to do |format|
      format.html
    end
  end
  
  # GET /animations
  # GET /animations.json
  def index
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
      format.html # show.html.erb
      format.json { render :json => @animation }
    end
  end

  # GET /animations/new
  # GET /animations/new.json
  def new
    respond_to do |format|
      format.html #{ render :layout => "new_rich"} # new.html.erb
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

  # GET /animations/createJson/:x1/:y1/:x2/:y2/:width/:height/:delay(cs)/:digitalid/:mode/:creator
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
    @animation.delay = arr[6].to_i
    @animation.digitalid = arr[7]
    @animation.mode = arr[8]
    @animation.creator = arr[9]
    
    # do some image magick
    # first get each frame
    im = Magick::Image.read(@animation.url).first
      
    fr1 = im.crop(@animation.x1,@animation.y1,@animation.width,@animation.height,true)
    fr2 = im.crop(@animation.x2,@animation.y2,@animation.width,@animation.height,true)
    
    # future filename
    unique = Digest::SHA1.hexdigest('nyplsalt' + Time.now.to_s)
    
    if @animation.mode == "GIF"
      # ANIMATED GIF!
      @animation.filename = unique + ".gif"
      
      final = Magick::ImageList.new
      final << fr1
      final << fr2
      final.ticks_per_second = 1000
      final.delay = @animation.delay
      final.iterations = 0
      
      fr3 = fr1.thumbnail(140,140)
      fr4 = fr2.thumbnail(140,140)
      thumb = Magick::ImageList.new
      thumb << fr3
      thumb << fr4
      thumb.ticks_per_second = 1000
      thumb.delay = @animation.delay
      thumb.iterations = 0
    else
      # ANAGLYPH!
      @animation.filename = unique + ".jpg"
      
      redlayer = Magick::Image.new(@animation.width,@animation.height){self.background_color = "#f00"}
      cyanlayer = Magick::Image.new(@animation.width,@animation.height){self.background_color = "#0ff"}
      
      fr1 = redlayer.composite(fr1, 0, 0, Magick::ScreenCompositeOp)
      fr2 = cyanlayer.composite(fr2, 0, 0, Magick::ScreenCompositeOp)
      final = fr1.composite(fr2, 0, 0, Magick::MultiplyCompositeOp)

      thumb = final.thumbnail(140,140)
    end
    
    # gotta packet the file
    final.write("#{Rails.root}/tmp/#{@animation.filename}") { self.quality = 100 }
    # and the thumb
    thumbname = "t_" + @animation.filename
    thumb.write("#{Rails.root}/tmp/#{thumbname}") { self.quality = 100 }
    
    # upload to Amazon S3
    s3 = AWS::S3.new
    bucket = s3.buckets['stereogranimator']
    obj = bucket.objects[@animation.filename]
    obj.write(:file => "#{Rails.root}/tmp/#{@animation.filename}", :acl => :public_read, :metadata => { 'photo_from' => 'New York Public Library' })
    obj = bucket.objects[thumbname]
    obj.write(:file => "#{Rails.root}/tmp/#{thumbname}", :acl => :public_read, :metadata => { 'photo_from' => 'New York Public Library' })
    
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
    
    # delete from Amazon S3
    s3 = AWS::S3.new
    bucket = s3.buckets['stereogranimator']
    obj = bucket.objects[@animation.filename]
    obj.delete()
    obj = bucket.objects["t_" + @animation.filename]
    obj.delete()
    
    @animation.destroy

    respond_to do |format|
      format.html { redirect_to animations_url }
      format.json { head :ok }
    end
  end
end
