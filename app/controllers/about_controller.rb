class AboutController < ApplicationController
  def what
  end
  
  def index
    @images = Animation.order('created_at DESC').limit(6)
  end

  def gif
  end
  
  def anaglyph
  end

  def stereogram
  end
end
