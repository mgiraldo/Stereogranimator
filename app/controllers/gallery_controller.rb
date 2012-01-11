class GalleryController < ApplicationController
  
  def index
    page = params[:page] == nil ? 1 : params[:page]
    @type = params[:type] == nil ? "all" : params[:type]
    if @type == "all"
      @images = Animation.order('created_at DESC').page(page).per(18)
    elsif @type == "gif" || @type == "anaglyph"
      @images = Animation.where("mode = ?", @type.upcase).order('created_at DESC').page(page).per(18)
    else
      @images = Animation.order('created_at DESC').page(page).per(18)
    end
    respond_to do |format|
      format.html # view.html.erb
      format.json { render :json => @images }
    end
  end
  
  # GET /view/1
  # GET /view/1.json
  def view
    @animation = Animation.find(params[:id])
    @animation.increaseViews

    bigurl = @animation.aws_url
    if @animation.mode == "JPEG"
      im = Magick::Image.read(bigurl).first
    else
      im = Magick::ImageList.new
      im.read(bigurl)
    end

    respond_to do |format|
      format.html # view.html.erb
      format.json { render :json => @animation }
      format.jpeg { render :text => im.to_blob{self.format = "JPEG"}, :status => 200, :type => 'image/jpeg' }
      format.gif { render :text => im.to_blob{self.format = "GIF"}, :status => 200, :type => 'image/gif' }
    end
  end
  
end
