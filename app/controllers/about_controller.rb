class AboutController < ApplicationController
  
  def what
  end
  
  def index
    ## LATEST IMAGES cache
    if Rails.cache.exist("home_images") == nil do
      @images = Animation.where("creator != ?", 'siege').order('created_at DESC').limit(6)
      Rails.cache.write("home_images", @images, :expires_in => 5.minutes)
    else
      @images = Rails.cache.read("home_images")
    end
    ## ANAGLYPH COUNT cache
    if Rails.cache.exist("home_anaglyphcount") == nil do
      @anaglyphcount = Animation.select('COUNT(id) as total').where('mode = ? AND creator != ?','ANAGLYPH','siege').map(&:total)[0].to_i
      Rails.cache.write("home_anaglyphcount", @anaglyphcount, :expires_in => 5.minutes)
    else
      @anaglyphcount = Rails.cache.read("home_anaglyphcount")
    end
    ## GIF COUNT cache
    if Rails.cache.exist("home_gifcount") == nil do
      @gifcount = Animation.select('COUNT(id) as total').where('mode = ? AND creator != ?','GIF','siege').map(&:total)[0].to_i
      Rails.cache.write("home_gifcount", @gifcount, :expires_in => 5.minutes)
    else
      @gifcount = Rails.cache.read("home_gifcount")
    end
    ## IMAGE COUNT cache
    if Rails.cache.exist("home_imagecount") == nil do
      @imagecount = Image.select('COUNT(id) as total').map(&:total)[0].to_i
      Rails.cache.write("home_imagecount", @imagecount, :expires_in => 5.minutes)
    else
      @imagecount = Rails.cache.read("home_imagecount")
    end
  end

  def animatedgif
  end
  
  def anaglyph
  end

  def stereoscopy
  end

  def credits
  end
  
  def collection
  end
end
