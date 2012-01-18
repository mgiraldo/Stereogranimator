class Animation < ActiveRecord::Base
  after_initialize :updateMetadata
  before_save :imageAndMetadata
  def imageAndMetadata
    @im = Image.where(:digitalid => self.digitalid).first
    @im.converted = 1
    @im.save
    updateMetadata()
    createImage()
  end
  def increaseViews
    self.views = self.views.to_i + 1
    self.save
  end
  def updateMetadata
    update = false
    if self.views == nil
      self.views = 0
      update = true
    end
    if self.metadata==nil && self.digitalid!=nil
      @im = Image.where(:digitalid => self.digitalid).first
      self.metadata = "#{@im.title} #{@im.date}"
      update = true
    end
    if update
      self.save
    end
  end
  def self.randomSet
    @images = Image.randomSet
    return @images
  end
  def createImage
    if self.filename==nil && self.digitalid!=nil
      # do some image magick
      # first get each frame
      im = Magick::Image.read(self.url).first
        
      # TODO: proper crop of thumbnails (?)
      fr1 = im.crop(self.x1,self.y1,self.width,self.height,true)
      fr2 = im.crop(self.x2,self.y2,self.width,self.height,true)
      
      # future filename
      unique = Digest::SHA1.hexdigest('nyplsalt' + Time.now.to_s)
      
      if self.mode == "GIF"
        # ANIMATED GIF!
        self.filename = unique + ".gif"
        
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
        self.filename = unique + ".jpg"
        
        redlayer = Magick::Image.new(self.width,self.height){self.background_color = "#f00"}
        cyanlayer = Magick::Image.new(self.width,self.height){self.background_color = "#0ff"}
        
        fr1 = redlayer.composite(fr1, 0, 0, Magick::ScreenCompositeOp)
        fr2 = cyanlayer.composite(fr2, 0, 0, Magick::ScreenCompositeOp)
        final = fr1.composite(fr2, 0, 0, Magick::MultiplyCompositeOp)
  
        thumb = final.resize_to_fill(140,140)
      end
      
      # gotta packet the file
      final.write("#{Rails.root}/tmp/#{self.filename}") { self.quality = 100 }
      # and the thumb
      thumbname = "t_" + self.filename
      thumb.write("#{Rails.root}/tmp/#{thumbname}") { self.quality = 100 }
      
      # upload to Amazon S3
      s3 = AWS::S3.new
      bucket = s3.buckets['stereogranimator']
      obj = bucket.objects[self.filename]
      obj.write(:file => "#{Rails.root}/tmp/#{self.filename}", :acl => :public_read, :metadata => { 'photo_from' => 'New York Public Library' })
      obj = bucket.objects[thumbname]
      obj.write(:file => "#{Rails.root}/tmp/#{thumbname}", :acl => :public_read, :metadata => { 'photo_from' => 'New York Public Library' })
    end
  end
  def url
    "http://images.nypl.org/index.php?id=#{digitalid}&t=w"
  end
  def thumb
    "/view/" + id.to_s + (mode=="GIF"?".gif":".jpeg") + "?n=1&m=t"
  end
  def full
    "/view/" + id.to_s + (mode=="GIF"?".gif":".jpeg") + "?n=1"
  end
  def aws_url
    "http://s3.amazonaws.com/stereogranimator/#{filename}"
  end
  def aws_thumb_url
    "http://s3.amazonaws.com/stereogranimator/t_#{filename}"
  end
  def nypl_url
    "http://digitalgallery.nypl.org/nypldigital/dgkeysearchdetail.cfm?&imageID=#{digitalid}"
  end
  def as_json(options = { })
      h = super(options)
      h[:url] = url
      h[:aws_url]   = aws_url
      h[:aws_thumb_url]   = aws_thumb_url
      h[:redirect] = "/share/#{id}"
      h
  end
end
