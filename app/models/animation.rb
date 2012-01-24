class Animation < ActiveRecord::Base
  before_save :imageAndMetadata
  before_destroy :checkImage
  def checkImage
    did = self.digitalid
    
    # delete from Amazon S3
    if self.filename != nil && self.filename != ""
      s3 = AWS::S3.new
      bucket = s3.buckets['stereo.nypl.org']
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
  def createImage(bypass=false)
    if (self.filename==nil && self.digitalid!=nil) || bypass
      # do some image magick
      # first get each frame
      im = "'#{self.url}'"
      
      basepath = "#{Rails.root}/tmp/"
      
      fr1 = "#{im} -crop #{self.width}x#{self.height}+#{self.x1}+#{self.y1} +repage"#im.crop(self.x1,self.y1,self.width,self.height,true)
      fr2 = "#{im} -crop #{self.width}x#{self.height}+#{self.x2}+#{self.y2} +repage"#im.crop(self.x2,self.y2,self.width,self.height,true)
      # future filename
      unique = Digest::SHA1.hexdigest('nyplsalt' + Time.now.to_s)
      
      if self.mode == "GIF"
        # ANIMATED GIF!
        self.filename = self.filename==nil ? unique + ".gif" : self.filename
        
#        final = Magick::ImageList.new
#        final << fr1
#        final << fr2
#        final.ticks_per_second = 1000
#        final.delay = self.delay
#        final.iterations = 0
        
#        fr3 = fr1.resize_to_fill(140,140)
#        fr4 = fr2.resize_to_fill(140,140)
#        thumb = Magick::ImageList.new
#        thumb << fr3
#        thumb << fr4
#        thumb.ticks_per_second = 1000
#        thumb.delay = self.delay
#        thumb.iterations = 0
        
        tmp1 = "convert #{fr1} #{basepath}tmp1#{self.filename}"
#        puts("TMP1: [#{tmp1}]")
        system(tmp1)
        tmp2 = "convert #{fr2} #{basepath}tmp2#{self.filename}"
#        puts("TMP2: [#{tmp2}]")
        system(tmp2)
        final = "convert -delay #{self.delay}x1000 -loop 0 #{basepath}tmp*#{self.filename} #{basepath}#{self.filename}"
      else
        # ANAGLYPH!
        self.filename = self.filename==nil ? unique + ".png" : self.filename
        
        fr1 = "#{fr1} -gamma 1,0,0" #fr1.gamma_correct(1,0,0)
        # save temp fr1 for composite
        tmp1 = "convert #{fr1} #{basepath}tmp1#{self.filename}"
#        puts("TMP1: [#{tmp1}]")
        system(tmp1)
        fr2 = "#{fr2} -gamma 0,1,1" #fr2.gamma_correct(0,1,1)
        # save temp fr2 for compsite
        tmp2 = "convert #{fr2} #{basepath}tmp2#{self.filename}"
#        puts("TMP1: [#{tmp2}]")
        system(tmp2)
        # the final composite anaglyph
        final = "composite -compose screen #{basepath}tmp1#{self.filename} #{basepath}tmp2#{self.filename} #{basepath}#{self.filename}" #fr2.composite fr1, Magick::CenterGravity, Magick::ScreenCompositeOp
      end
      
      format = self.mode=="GIF"?"gif":"png"
      # gotta packet the file
      system(final)#final.write("#{format}:#{Rails.root}/tmp/#{self.filename}") { self.quality = 100 }
#      puts("FINAL: [#{final}]")
      
      # thumbnail
      thumbname = "t_" + self.filename
      if self.width > self.height
        t = "h"
      elsif self.height > self.width
        t = "v"
      else 
        t = "s"
      end
      
      #only need to crop if not s (square)
      if  t == "h"
        crop = " -crop #{self.height}x#{self.height}+#{((self.width-self.height)/2).to_i}+0! "
      elsif t == "v"
        crop = " -crop #{self.width}x#{self.width}+0+#{((self.height-self.width)/2).to_i}! "
      end
      crop = "#{crop}"#final.resize_to_fill(140,140)

      thumbcmd = "convert #{basepath}#{self.filename} +repage #{crop} -resize 140x140 #{basepath}#{thumbname}"
#      puts("THUMB: [#{thumbcmd}]")
      system(thumbcmd)#thumb.write("#{format}:#{Rails.root}/tmp/#{thumbname}") { self.quality = 100 }
      
      # upload to Amazon S3
      s3 = AWS::S3.new
      bucket = s3.buckets['stereo.nypl.org']
      obj = bucket.objects[self.filename]
      obj.write(:file => "#{basepath}#{self.filename}", :acl => :public_read, :metadata => { 'description' => self.metadata, 'photo_from' => 'New York Public Library' })
      obj = bucket.objects[thumbname]
      obj.write(:file => "#{basepath}#{thumbname}", :acl => :public_read, :metadata => { 'description' => self.metadata, 'photo_from' => 'New York Public Library' })
    end
  end
  def self.purgeBlacklisted
    # create an array with kosher images
    white = Image.find(:all, :select=>"digitalid").map(&:digitalid)
    # select all animations not present in the images table
    black = Animation.where("digitalid NOT IN (?)", white)
    # destroy those animations
    black.destroy_all
  end
  def self.recreateAWS
    # get all animations
    batch = Animation.all
    # run createImage on each using the filename found
    batch.each do |an|
      an.createImage(true)
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
    "http://s3.amazonaws.com/stereo.nypl.org/#{filename}"
  end
  def aws_thumb_url
    "http://s3.amazonaws.com/stereo.nypl.org/t_#{filename}"
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
