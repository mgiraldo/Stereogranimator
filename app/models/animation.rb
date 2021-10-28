class Animation < ActiveRecord::Base
  before_save :createImage
  before_destroy :checkImage
  attr_accessor :skip_derivatives

  def checkImage
    did = self.digitalid
    xid = self.external_id

    # delete from Amazon S3
    if self.filename != nil && self.filename != ""
      s3 = AWS::S3.new
      bucket = s3.buckets['stereo.nypl.org']
      obj = bucket.objects[self.filename]
      obj.delete()
      obj = bucket.objects["t_" + self.filename]
      obj.delete()
    end

    @derivatives = Animation.where(:digitalid => did, :external_id => xid)

    if @derivatives.length == 1
      # this is the last derivative for the original image IF FROM NYPL
      @im = Image.where("upper(digitalid) = ?", did.upcase).first
      if @im != nil
        @im.converted = 0
        @im.save
      end
    end
  end
  def increaseViews
    self.views = self.views.to_i + 1
    self.save
  end
  def createImage
    return if self.skip_derivatives
    url = self.url
    if self.external_id!=0
      external_photo = Image.flickrDataForPhoto(self.digitalid)
      if external_photo != nil
        url = external_photo[:original_url]
      else
        url = nil
      end
    end
    if (url && self.filename==nil && self.digitalid!=nil)
      # do some image magick
      # first get each frame
      # remove the https (flickr doesnt like heroku in https)
      url = url.gsub(/https:/, 'http:')
      im = Magick::Image.read(url).first

      if (im.columns > 800)
        im = im.resize_to_fit(800)
      end

      if (im.rows > 600)
        im = im.resize_to_fit(800,600)
      end

      rot = self.rotation == "" ? 0 : self.rotation.to_f

      im.background_color = "none"
      im = im.rotate(rot)

      # TODO: proper crop of thumbnails (?)
      fr1 = im.crop(self.x1,self.y1,self.width,self.height,true)
      fr2 = im.crop(self.x2,self.y2,self.width,self.height,true)

      # future filename
      unique = Digest::SHA1.hexdigest('nyplsalt' + Time.now.to_s)

      if self.mode == "GIF"
        # ANIMATED GIF!
        self.filename = self.filename==nil ? unique + ".gif" : self.filename

        final = Magick::ImageList.new
        final << fr1
        final << fr2
        final.ticks_per_second = 1000
        final.delay = self.delay
        final.iterations = 0

        fr3 = fr1.resize_to_fill(140,140)
        fr4 = fr2.resize_to_fill(140,140)
        thumb = Magick::ImageList.new
        thumb << fr3
        thumb << fr4
        thumb.ticks_per_second = 1000
        thumb.delay = self.delay
        thumb.iterations = 0
      else
        # ANAGLYPH!
        self.filename = self.filename==nil ? unique + ".png" : self.filename

        fr1 = fr1.gamma_correct(1,0,0)
        fr2 = fr2.gamma_correct(0,1,1)
        final = fr2.composite fr1, Magick::CenterGravity, Magick::ScreenCompositeOp

        thumb = final.resize_to_fill(140,140)
      end

      format = self.mode=="GIF"?"gif":"png"
      # gotta packet the file
      final.write("#{format}:#{Rails.root}/tmp/#{self.filename}") { self.quality = 100 }
      # and the thumb
      thumbname = "t_" + self.filename
      thumb.write("#{format}:#{Rails.root}/tmp/#{thumbname}") { self.quality = 100 }

      # upload to Amazon S3
      s3 = AWS::S3.new
      bucket = s3.buckets['stereo.nypl.org']
      obj = bucket.objects[self.filename]
      obj.write(:file => "#{Rails.root}/tmp/#{self.filename}", :acl => :public_read, :metadata => { 'description' => URI.escape(self.metadata), 'photo_from' => 'NYPL Labs Stereogranimator' })
      obj = bucket.objects[thumbname]
      obj.write(:file => "#{Rails.root}/tmp/#{thumbname}", :acl => :public_read, :metadata => { 'description' => URI.escape(self.metadata), 'photo_from' => 'NYPL Labs Stereogranimator' })
    end
  end

  def owner
    if self.external_id==0
      "New York Public Library"
    else
      if self.external_id == -1
        data = Image.flickrDataForPhoto(self.digitalid)
        if (data)
          data[:info]["owner"]["username"]
        else
          "Flickr"
        end
      else
        data = Image.externalData(self.external_id)
        if (data)
          data[:name]
        else
          "[N/A]"
        end
      end
    end
  end

  def owner_url
    if self.external_id==0
      "http://nypl.org"
    else
      Image.externalData(self.external_id)[:homeurl]
    end
  end

  def original_url
    if self.external_id==0
      self.nypl_url
    else
      data = Image.flickrDataForPhoto(self.digitalid)
      if (data)
        data[:info]["urls"][0]["_content"]
      else
        ""
      end
    end
  end

  def url
    if external_id != 1
      "http://images.nypl.org/index.php?id=#{digitalid}&t=w"
    else
      Image.flickrDataForPhoto(digitalid)[:original_url]
    end
  end

  def share_url
    "/view/" + id.to_s
  end

  def thumb
    "/view/#{id.to_s}#{(mode=="GIF"?".gif":".png")}?n=1&m=t"
  end
  
  def full
    "/view/#{id.to_s}#{(mode=="GIF"?".gif":".png")}?n=1"
  end

  def full_count
    "/view/#{id.to_s}#{(mode=="GIF"?".gif":".png")}"
  end

  def deriv_url
    "http://s3.amazonaws.com/stereo.nypl.org/#{filename}" # "https://mauriciogiraldo.com/stereoderivs/#{filename}"
  end
  
  def deriv_thumb_url
    "http://s3.amazonaws.com/stereo.nypl.org/t_#{filename}" # "https://mauriciogiraldo.com/stereoderivs/t_#{filename}"
  end

  def nypl_url
    "http://digitalcollections.nypl.org/items/image_id/#{digitalid.downcase}"
  end

  def as_json(options = { })
      h = super(options)
      h[:url] = url
      h[:deriv_url]   = deriv_url
      h[:deriv_thumb_url]   = deriv_thumb_url
      h[:redirect] = "#{id}"
      h
  end




  
  
  
  def nypl_url
    "http://digitalgallery.nypl.org/nypldigital/dgkeysearchdetail.cfm?imageID=#{digitalid.downcase}"
  end
  
  def as_json(options = { })
      h = super(options)
      h[:url] = url
      h[:deriv_url]   = deriv_url
      h[:deriv_thumb_url]   = deriv_thumb_url
      h[:redirect] = "/share/#{id}"
      h
  end

  def self.purgeBlacklisted
    # create an array with kosher images
    white = Image.where(:all, :select=>"digitalid").map(&:digitalid)
    # select all animations not present in the images table
    black = Animation.where("digitalid NOT IN (?)", white)
    # destroy those animations
    black.destroy_all
  end
  def self.recreateDB
    animations = []
    File.open("scrape/combined.json", 'r') {
      |f|
      dec = ActiveSupport::JSON.decode f.read
      dec.each do |d|
        a = ActiveSupport::HashWithIndifferentAccess.new(d)
        a.except!(:url, :deriv_url, :deriv_thumb_url, :redirect)
        puts "saving #{a[:id]}"
        temp = Animation.new(a)
        temp.skip_derivatives = true
        temp.save!
      end
    }
  end
  def self.recreateAWS
    #
    #
    #  COMMENTED WHEN ADDED FLICKR INTEGRATION WHICH BREAKS THIS
    #
    #
    # get all animations
    #batch = Animation.all
    # run createImage on each using the filename found
    #batch.each do |an|
      #an.createImage(true)
    #end
  end

  def self.amazonDump
    countgif = 0
    countana = 0
    totalgiff = 0
    totalgift = 0
    totalanaf = 0
    totalanat = 0

    s3 = AWS::S3.new
    bucket = s3.buckets['stereo.nypl.org']
    bucket.objects.each do |ob|
      tmpurl = ob.public_url.to_s
      if tmpurl.index("gif") != nil
        puts "GIF"
        countgif+=1
        if tmpurl.index("t_") != nil
          totalgift += ob.content_length
        else
          totalgiff += ob.content_length
        end
      else
        puts "PNG/JPEG"
        countana+=1
        if tmpurl.index("t_") != nil
          totalanat += ob.content_length
        else
          totalanaf += ob.content_length
        end
      end
    end
    if countgif > 0
      puts "Average GIF big size: #{(totalgiff/countgif).round.to_s}"
      puts "Average GIF thumb size: #{(totalgift/countgif).round.to_s}"
    end
    if countana > 0
      puts "Average JPG big size: #{(totalanaf/countana).round.to_s}"
      puts "Average JPG thumb size: #{(totalanat/countana).round.to_s}"
    end
    puts "There were #{countana} PNGs/JPEGs and #{countgif} GIFs "
  end

  def self.process_takedowns
    # look at all flickr urls
    takedowns = 0
    # see if it functional (non-404)
    candidates = Animation.where(:external_id => -1)
    candidates.each do |animation|
      # puts animation.original_url
      if animation.original_url == ""
        # Flickr returned nil... we must delete
        takedowns = takedowns + 1
        animation.destroy
      end
    end
  end
end
