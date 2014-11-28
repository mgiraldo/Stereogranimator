class AnimationsController < ApplicationController
  before_filter :require_user, :only => [:index, :edit, :destroy]

  # GET /choose
  def choose
    # @get_from_flickr = false
    @images = Image.randomSet(@get_from_flickr) # @get_from_flickr is in app controller
    respond_to do |format|
      format.html
    end
  end

  def chooseSearch
    xid = 1
    # checkFlickrCookies()
    xid = params[:xid].to_i if params[:xid] != nil
    @images = Image.findByKeyword(params[:keyword], xid)
    respond_to do |format|
      format.html { render :json => @images }
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
    # checkFlickrCookies()
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

  # GET /choose
  def choose_publiceye
    get_from_flickr = false
    nypl_only = true
    @images = Image.randomSet(get_from_flickr, nypl_only)
    respond_to do |format|
      format.html { render :layout => "publiceye" }
    end
  end

  def chooseSearch_publiceye
    xid = 0
    @images = Image.findByKeyword(params[:keyword], xid)
    respond_to do |format|
      format.html { render :json => @images }
      format.json { render :json => @images }
    end
  end

  # GET /animations/new
  # GET /animations/new.json
  def new_publiceye
    # checkFlickrCookies()
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
        format.html { render :layout => "publiceye" }
      end
    end
  end

  def share_publiceye
    @animation = Animation.find(params[:id])

    respond_to do |format|
      format.html { render :layout => "publiceye" }
    end
  end

  def share_js_publiceye
    puts "Attempted share for id #{params[:id]}, username #{params[:name]}, email #{params[:email]}"

    animation = Animation.find(params[:id])

    url = url_for(:controller=>"gallery",:action=>"view",:id=>animation.id,:only_path => false)

    if params[:email] && is_valid_email(params[:email])
      email = params[:email]

      hdr = {
        :filters =>
        {
          :templates => {
            :settings => {
              :enable => 1,
              :template_id => "e8f89441-7c6c-4144-81fd-02cc622625e6"
            }
          }
        }
      }

      # puts hdr.to_json()

      html = '<html>
<head>
  <title></title>
</head>
<body>
<p style="text-align: center;"><img alt="NYPL Labs Stereogranimator" src="https://marketing-image-production.s3.amazonaws.com/uploads/df12af12a32f2d70f6f2e2c1ffab365297610b86b255a24efe90dd930aeadc96193d03262d0732f34b7fa1a8334d4078945eec672d607bcf9a0f8aca98def37e/bd2731858b0b9a76544f839ba2214f4c6fc6cf8eb7650c8f6107e0f0__ecc382d3-a0a9-4cde-9294-2772355361eb.png" style="width: 300px; height: 112px;" /></p>

<p style="text-align: center;"><span style="font-size:12px;"><span style="font-family:arial,helvetica,sans-serif;"><%body%></span></span></p>

<p style="text-align: center;"><span style="font-size:12px;"><span style="font-family:arial,helvetica,sans-serif;">---</span></span></p>

<p style="text-align: center;"><a href="http://stereo.nypl.org"><span style="font-size:12px;"><span style="font-family:arial,helvetica,sans-serif;">Visit Stereogranimator</span></span></a></p>

<p style="text-align: center;"><a href="http://nypl.org"><font face="arial, helvetica, sans-serif"><span style="font-size: 12px;">The New York Public Library</span></font></a></p>
</body>
</html>'

      body_plain = 'Hello!\n\nYou created an image in the NYPL Public Eye exhibition\nand requested us to send it to you.\n\nYour image can be found at:\n##url##\n\n\nBest,\nNYPL Labs\nhttp://stereo.nypl.org'

      body_html = body_plain.gsub(/\\n/,'<br />')
      body_html = body_html.gsub(/##url##/,"<a href='#{url}'><img src='#{url}.gif' /></a>")
      html = html.gsub(/<%body%>/, body_html)

      # puts body_plain
      # puts body_html


      Mail.deliver do
        # header['X-SMTPAPI'] =  hdr.to_json()
        to "#{email}"
        from 'stereo@nypl.org'
        subject 'The Stereogranimator image you created'
        text_part do
          body "#{body_plain}"
        end
        html_part do
          content_type 'text/html; charset=UTF-8'
          body "#{html}"
        end
      end
    elsif params[:name] =~ /^([a-zA-Z](_?[a-zA-Z0-9]+)*_?|_([a-zA-Z0-9]+_?)*)$/ || params[:name] =~ /^@([a-zA-Z](_?[a-zA-Z0-9]+)*_?|_([a-zA-Z0-9]+_?)*)$/
      puts "yes tweet: #{params[:name]} contains @? #{params[:name].include? '@'}"
      username = params[:name]
      username = "@#{username}" unless username.include?("@")
      update = "(test) Check out this image: #{url}"
      update += " by #{username}" unless username == "@nypl_stereo"
      update += "\nCreated with #Stereogranimator"
      $twitter_client.update(update)
    end

    respond_to do |format|
      format.html { render :json => "true" }
    end
  end

  def is_valid_email(value)
    begin
      m = Mail::Address.new(value)
      # We must check that value contains a domain and that value is an email address
      r = m.domain && m.address == value
      t = m.__send__(:tree)
      # We need to dig into treetop
      # A valid domain must have dot_atom_text elements size > 1
      # user@localhost is excluded
      # treetop must respond to domain
      # We exclude valid email values like <user@localhost.com>
      # Hence we use m.__send__(tree).domain
      r &&= (t.domain.dot_atom_text.elements.size > 1)
    rescue Exception => e
      r = false
    end
    r
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
    if session[:last_create] != nil && current - session[:last_create] < 5 # can only create one every 10 seconds
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
    # checkFlickrCookies()
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
