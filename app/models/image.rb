class Image < ActiveRecord::Base
  def thumb_url
    "http://images.nypl.org/index.php?id=#{digitalid}&t=r"
  end
  def big_url
    "http://images.nypl.org/index.php?id=#{digitalid}&t=w"
  end
  def self.randomSet
    @images = {}
    @images['all'] = Array.new
    @images['subset'] = Array.new
    dbimages = Image.where(:converted => 0).order('random()').limit(100)
    if dbimages.length > 0
      # check in case all images have been converted
      if dbimages.length == 0
        dbimages = Image.order('random()').limit(100)
      end
      dbimages.each do |e|
        @images['all'].push(e.digitalid)
      end
      (0..8).each do |i|
        @images['subset'][i] = dbimages[i]
      end
    end
    return @images
  end
  def self.getMetadata (did)
    image = Image.where(:digitalid => did).first
    @meta = {}
    if  image != nil
      @meta = {"title" => "#{image.title} (#{image.date})", "link" => "http://digitalgallery.nypl.org/nypldigital/id?#{image.digitalid}" }
    end
    return @meta
  end
  def self.pushToDB
    File.open("dennis_images.txt", 'r') {
      |f|
      dec = ActiveSupport::JSON.decode f
      dec['response']['docs'].each do |d|
        temp = Image.new(:digitalid => d['image_id'], :title => d['title'])
        if d['dc_coverage'] != nil
          temp.date = d['dc_coverage'].join(" ")
        end
        temp.save
      end
    }
  end
end
