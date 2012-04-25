class Image < ActiveRecord::Base
  def isFlickr
    self[:isFlickr]==nil ? false : self[:isFlickr]
  end
  
  def isFlickr=(val)
    self[:isFlickr]=val
  end
  
  def thumb_url
    "http://images.nypl.org/index.php?id=#{digitalid}&t=r"
  end
  
  def big_url
    "http://images.nypl.org/index.php?id=#{digitalid}&t=w"
  end
  
  def self.galleryCollectionList
    l = {:id=>0, :name=>"New York Public Library"}
    r = [l]
    self.flickr_sets.each do |s|
      r.push({:id=>s[:id], :name=>s[:name]})
    end
    return r
  end
  
  def self.flickr_sets
    #ids from flickr to include in queries
    [{:id=>1, :set_id=>"72157604192771132", :owner_id=>"24029425@N06", :name=>"Boston Public Library", :baseurl=>"http://www.flickr.com/photos/boston_public_library/", :homeurl=>"http://www.bpl.org/"}]
  end
  
  def self.externalData(id)
    return self.flickr_sets.select{|f| f[:id]==id}[0]
  end
  
  def self.ownerExists(id)
    return self.flickr_sets.select{|f| f[:owner_id]==id}.length>0
  end
  
  def self.flickrDataForPhoto(id)
    begin
      info = flickr.photos.getInfo(:photo_id => id)
    rescue
      return nil
    else
      output = {:info => info, :original_url  => FlickRaw.url_o(info)}
      return output
    end
  end
  
  def self.verifyFlickrPhoto(id)
    begin
      info = flickr.photos.getInfo(:photo_id => id)
    rescue
      return false
    else
      if !Image.ownerExists(info["owner"]["nsid"])
        return false
      end
      return FlickRaw.url_o(info)
    end
  end
  
  def self.listFromFlickrSet(set_id)
    # get set info to figure out image count
    begin
      info = flickr.photosets.getInfo(:photoset_id => set_id)
    rescue
      return nil
    else
      # retreive a random-ish group
      if info["photos"].to_i == 0
        return nil
      end
      total = info["photos"].to_i
      max = 20 #max photos to bring
      count = total < max ? total : max
      lastindex = ((total-count).to_f/max.to_f).ceil
      page = rand(lastindex)+1
      extras = "url_m, url_o, owner_name"
      begin
        list = flickr.photosets.getPhotos(:photoset_id => set_id, :extras=>extras, :page=>page, :per_page=>count)
      rescue
        puts "NO PHOTOS"
        return nil
      else
        return list["photo"]
      end 
    end
  end
  
  def self.randomSet
    @images = {}
    @images['all'] = Array.new
    @images['subset'] = Array.new
    # get 100 images from NYPL list
    dbimages = Image.where(:converted => 0).order('random()').limit(100)
    # check in case all images have been converted
    if dbimages.length == 0 || dbimages.length < 9
      dbimages = Image.order('converted ASC, random()').limit(100)
    end
    dbimages.each do |e|
      @images['all'].push({:id=>e.digitalid.upcase,:xid=>0,:url=>e.thumb_url,:owner=>"From: NYPL Digital Gallery"})
    end
    # add some images from external resources (Flickr)
    Image.flickr_sets.each do |set|
      # get the photos
      external = Image.listFromFlickrSet(set[:set_id])
      # append them to dbimages
      if external != nil
        external.each do |ext|
          @images['all'].push({:id=>ext["id"],:xid=>set[:id],:url=>ext["url_m"],:owner=>"From: " + Image.externalData(set[:id])[:name]})
        end
      end
    end
    @images['all'] = @images['all'].shuffle
    (0..8).each do |i|
      @images['subset'][i] = {:id=>@images['all'][i][:id],:xid=>@images['all'][i][:xid],:url=>@images['all'][i][:url],:owner=>@images['all'][i][:owner]}
    end
    return @images
  end
  
  def meta
    "#{title} #{date}"
  end
  
  def self.getMetadata (did)
    image = Image.where("upper(digitalid) = ?", did.upcase).first
    @meta = {}
    if  image != nil
      @meta = {"title" => "#{image.title} (#{image.date})", "link" => "http://digitalgallery.nypl.org/nypldigital/id?#{image.digitalid}", "homeurl" => "http://nypl.org" }
    end
    return @meta
  end
  
  def self.pushToDB
    File.open("dennis_images.txt", 'r') {
      |f|
      dec = ActiveSupport::JSON.decode f
      dec['response']['docs'].each do |d|
        temp = Image.new(:digitalid => d['image_id'], :title => d['title'].to_s)
        if d['dc_coverage'] != nil
          temp.date = d['dc_coverage'].join(" ")
        end
        temp.save
      end
    }
  end
  
  def self.findByKeyword(keyword)
    bpl = self.externalData(1)
    r = []
    local = Image.select('digitalid').where('UPPER(title) LIKE ?', "%#{keyword.upcase}%")
    local.each{|x|r.push({:id=>x[:digitalid],:owner=>"From: NYPL Digital Gallery",:xid=>0,:url=>x.thumb_url})}
    begin
      info = flickr.photos.search(:user_id => bpl[:owner_id],:tags=>"stereograph,#{keyword}",:tag_mode=>'all',:per_page=>20)
    rescue
      return r
    else
      info.each{|x|r.push({:id=>x["id"],:xid=>1,:owner=>"From: #{bpl[:name]}",:url=>FlickRaw.url_m(x)})}
      return r
    end
  end
end
