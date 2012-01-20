class AboutController < ApplicationController
  def what
  end
  
  def index
    @images = Animation.order('created_at DESC').limit(6)
    @anaglyphcount = Animation.where(:mode=>'ANAGLYPH').length
    @gifcount = Animation.where(:mode=>'GIF').length
    @imagecount = Image.all.length
  end

  def gif
  end
  
  def anaglyph
  end

  def stereogram
  end

  def credits
  end
end
