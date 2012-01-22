class Animation < ActiveRecord::Base
  after_initialize :updateMetadata
  before_save :imageAndMetadata
  before_destroy :checkImage
  def checkImage
    did = self.digitalid
    
    # delete from Amazon S3
    if self.filename != nil && self.filename != ""
      s3 = AWS::S3.new
      bucket = s3.buckets['stereogranimator']
      obj = bucket.objects[self.filename]
      obj.delete()
      obj = bucket.objects["t_" + self.filename]
      obj.delete()
    end
    
    @derivatives = Animation.where(:digitalid => did)
    
    if @derivatives.length == 1
      # this is the last derivative for the original image
      @im = Image.where("upper(digitalid) = ?", did.upcase).first
      if @im != nil
        @im.converted = 0
        @im.save
      end
    end
  end
  def imageAndMetadata
    @im = Image.where("upper(digitalid) = ?", self.digitalid.upcase).first
    if @im != nil
      @im.converted = 1
      @im.save
    end
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
      @im = Image.where("upper(digitalid) = ?", self.digitalid.upcase).first
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
        self.filename = unique + ".png"
        
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
      bucket = s3.buckets['stereogranimator']
      obj = bucket.objects[self.filename]
      obj.write(:file => "#{Rails.root}/tmp/#{self.filename}", :acl => :public_read, :metadata => { 'photo_from' => 'New York Public Library' })
      obj = bucket.objects[thumbname]
      obj.write(:file => "#{Rails.root}/tmp/#{thumbname}", :acl => :public_read, :metadata => { 'photo_from' => 'New York Public Library' })
    end
  end
  def self.amazonDump
    countgif = 0
    countana = 0
    totalgiff = 0
    totalgift = 0
    totalanaf = 0
    totalanat = 0
    
    s3 = AWS::S3.new
    bucket = s3.buckets['stereogranimator']
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
  def url
    "http://images.nypl.org/index.php?id=#{digitalid}&t=w"
  end
  def thumb
    "/view/" + id.to_s + (mode=="GIF"?".gif":".png") + "?n=1&m=t"
  end
  def full
    "/view/" + id.to_s + (mode=="GIF"?".gif":".png") + "?n=1"
  end
  def full_count
    "/view/" + id.to_s + (mode=="GIF"?".gif":".png")
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
