class AboutController < ApplicationController

  caches_action :index, :expires_in => 2.minutes, :cache_path => "home"

  def what
  end

  def index
    @images = Animation.where("creator != ? AND external_id != -1", 'siege').order('created_at DESC').limit(6)
    @popular = Animation.where("creator != ? AND views > 300 AND external_id != -1", 'siege').order(Arel.sql('random()')).limit(6)
    @random = Animation.where("creator != ? AND external_id != -1", 'siege').order(Arel.sql('random()')).limit(6)
    @anaglyphcount = Animation.select('COUNT(id) as total').where('mode = ? AND creator != ?','ANAGLYPH','siege').map(&:total)[0].to_i
    @gifcount = Animation.select('COUNT(id) as total').where('mode = ? AND creator != ?','GIF','siege').map(&:total)[0].to_i
    @imagecount = Image.select('COUNT(id) as total').map(&:total)[0].to_i
    @imagecount += Image.countFlickrPhotos
    @collectioncount = 1 + Image.flickr_sets.count
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
