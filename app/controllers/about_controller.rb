class AboutController < ApplicationController
  
  caches_page :index, :expires_in => 2.minutes
  
  def what
  end
  
  def index
    @images = Animation.where("creator != ?", 'siege').order('created_at DESC').limit(6)
    @popular = Animation.where("creator != ?", 'siege').order('views DESC').limit(6)
    @random = Animation.where("creator != ?", 'siege').order('random()').limit(6)
    @anaglyphcount = Animation.select('COUNT(id) as total').where('mode = ? AND creator != ?','ANAGLYPH','siege').map(&:total)[0].to_i
    @gifcount = Animation.select('COUNT(id) as total').where('mode = ? AND creator != ?','GIF','siege').map(&:total)[0].to_i
    @imagecount = Image.select('COUNT(id) as total').map(&:total)[0].to_i
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
