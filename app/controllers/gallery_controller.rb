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
    count = true
    redirect = @animation.aws_url
    if params[:n]
      count = false
    end
    if count
      @animation.increaseViews
    end
    if params[:m]=="t"
      redirect = @animation.aws_thumb_url
    end
    respond_to do |format|
      format.html # view.html.erb
      format.json { render :json => @animation }
      format.jpeg { redirect_to redirect }
      format.gif { redirect_to redirect }
    end
  end
  
end
