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
    r = [{:id=>0, :name=>"New York Public Library"}]
    self.flickr_sets.each do |s|
      r.push({:id=>s[:id], :name=>s[:name]})
    end
    r.push({:id=>-1, :name=>"Flickr community"})
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
      # Flickr returns nil for 404s and other images that are not accessible for all
      return nil
    else
      output = {:info => info, :original_url  => FlickRaw.url_b(info)} # changed from url_o since not all flickr users will be pro
      return output
    end
  end

  def self.verifyFlickrPhoto(id)
    begin
      info = flickr.photos.getInfo(:photo_id => id)
    rescue
      return false
    else
      # all flickr images are potentially allowed now
      # if !Image.ownerExists(info["owner"]["nsid"])
      #   return false
      # end
      return FlickRaw.url_b(info)
    end
  end

  def self.countFlickrPhotos
    count = 0
    Image.flickr_sets.each do |set|
      begin
        info = flickr.photosets.getInfo(:photoset_id => set[:set_id])
      rescue
      else
        count += info["count_photos"].to_i
      end
    end
    return count
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

  def self.randomSet (personal, nypl_only=false)
    @images = {}
    @images['all'] = Array.new
    @images['subset'] = Array.new
    # check for personal photos
    if personal
      # only user photos in flickr
      extras = "url_m, url_o, owner_name"
      all = flickr.photos.search(:content_type => 1, :media => "photos", :user_id => "me", :extras => extras)
      all.each do |ext|
        @images['all'].push({:id=>ext["id"],:xid=>-1,:url=>ext["url_m"],:owner=>"From Flickr user <a href=\"http://www.flickr.com/user/" + ext["owner"] + "\">" + ext["ownername"] + "</a>"})
      end
      @images['all'] = @images['all'].shuffle
      if @images['all'].count > 0
        max_images = 9
        num_images = 0
        @images['all'].each_with_index do |k,i|
          @images['subset'][i] = {:id=>@images['all'][i][:id],:xid=>@images['all'][i][:xid],:url=>@images['all'][i][:url],:owner=>@images['all'][i][:owner]}
          num_images = num_images + 1
          break if num_images >= max_images
        end
      end
    else
      # get 100 images from NYPL list
      # dbimages = Image.where(:converted => 0).order('random()').limit(100)
      dbimages = Image.order('converted ASC, random()').limit(100)
      # check in case all images have been converted
      if dbimages.length == 0 || dbimages.length < 9
        dbimages = Image.order('converted ASC, random()').limit(100)
      end
      dbimages.each do |e|
        @images['all'].push({:id=>e.digitalid.upcase,:xid=>0,:url=>e.thumb_url,:owner=>"From: New York Public Library"})
      end
      # add some images from external resources (Flickr)
      if !nypl_only
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
      end
      @images['all'] = @images['all'].shuffle
      (0..8).each do |i|
        @images['subset'][i] = {:id=>@images['all'][i][:id],:xid=>@images['all'][i][:xid],:url=>@images['all'][i][:url],:owner=>@images['all'][i][:owner]}
      end
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
      @meta = {"title" => "#{image.title} (#{image.date})", "owner" => "New York Public Library", "link" => "http://digitalcollections.nypl.org/items/image_id/#{image.digitalid}", "homeurl" => "http://nypl.org" }
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

  def self.findByKeyword(keyword, xid)
    # following line only for BPL set
    bpl = self.externalData(xid) unless xid == -1

    r = []

    # standard internal image search
    # not to use if searching my flickr photos only
    if xid != -1
      local = Image.select('digitalid').where('UPPER(title) LIKE ?', "%#{keyword.gsub(/\+/, ' ').upcase}%")
      local.each{|x|r.push({:id=>x[:digitalid],:owner=>"From: New York Public Library",:xid=>0,:url=>x.thumb_url})}
    end
    begin
      # search teh flickrz
      if xid != -1
        userid = bpl[:owner_id]
        keyword = "stereograph #{keyword}"
      else
        userid = "me"
      end
      extras = "url_m, url_o, owner_name"
      info = flickr.photos.search(:content_type => 1, :media => "photos", :user_id => userid,:text=>"#{keyword}",:tag_mode=>'all',:per_page=>20,:extras => extras)
    rescue
      return r
    else
      # following line works only for BPL
      # info.each{|x|r.push({:id=>x["id"],:xid=>1,:owner=>"From: #{bpl[:name]}",:url=>FlickRaw.url_m(x)})}
      if xid != -1
        info.each{|x|r.push({:id=>x["id"],:xid=>xid,:owner=>"From: #{bpl[:name]}",:url=>FlickRaw.url_m(x)})}
      else
        info.each{|x|r.push({:id=>x["id"],:xid=>xid,:owner=>"From Flickr user <a href=\"http://www.flickr.com/user/" + x["owner"] + "\">" + x["ownername"] + "</a>",:url=>FlickRaw.url_m(x)})}
      end
      return r
    end
  end
end
