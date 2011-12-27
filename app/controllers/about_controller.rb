class AboutController < ApplicationController
  def what
  end
  
  def index
    @images = Animation.order('created_at DESC').limit(6)
  end
end
