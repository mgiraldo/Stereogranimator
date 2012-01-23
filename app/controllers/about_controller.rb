class AboutController < ApplicationController
  def what
  end
  
  def index
    @images = Animation.order('created_at DESC').limit(6)
    @anaglyphcount = Animation.where(:mode=>'ANAGLYPH').length
    @gifcount = Animation.where(:mode=>'GIF').length
    @imagecount = Image.all.length
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
