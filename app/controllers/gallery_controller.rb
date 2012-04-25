class GalleryController < ApplicationController
  
  def index
    per = 30
    page = params[:page] == nil ? 1 : params[:page]
    @type = params[:type] == nil ? "all" : params[:type]
    xid = params[:xid] == nil || params[:xid] == "" ? -1 : params[:xid]
    xidwhere = (xid != -1) ? " AND external_id = ? " : " AND external_id != ? "
    if params[:q] == nil
      if @type == "all"
        @images = Animation.where("creator != ? #{xidwhere}", 'siege', xid).order('created_at DESC').page(page).per(per)
        @total = Animation.select('COUNT(id) as total').where("creator != ? #{xidwhere}", 'siege', xid).map(&:total)[0].to_i
      elsif @type == "gif" || @type == "anaglyph"
        @images = Animation.where("mode = ? AND creator != ? #{xidwhere}", @type.upcase, 'siege', xid).order('created_at DESC').page(page).per(per)
        @total = Animation.select('COUNT(id) as total').where("mode = ? AND creator != ? #{xidwhere}", @type.upcase, 'siege', xid).map(&:total)[0].to_i
      elsif @type == "popular"
        @images = Animation.where("creator != ? #{xidwhere}", 'siege', xid).order('views DESC').page(page).per(per)
        @total = Animation.select('COUNT(id) as total').where("creator != ? #{xidwhere}", 'siege', xid).map(&:total)[0].to_i
      else
        @images = Animation.where("creator != ? #{xidwhere}", 'siege', xid).order('created_at DESC').page(page).per(per)
        @total = Animation.select('COUNT(id) as total').where("creator != ? #{xidwhere}", 'siege', xid).map(&:total)[0].to_i
      end
    else
      @images = Animation.where("creator != ? AND UPPER(metadata) LIKE ? #{xidwhere}", 'siege', "%#{params[:q].upcase}%", xid).order('created_at DESC').page(page).per(per)
      @total = Animation.select('COUNT(id) as total').where("creator != ? AND UPPER(metadata) LIKE ? #{xidwhere}", 'siege', "%#{params[:q].upcase}%", xid).map(&:total)[0].to_i
    end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @images }
    end
  end
  
  # GET /view/1
  # GET /view/1.json
  def view
    @animation = Animation.find(params[:id])
    count = true
    redirect = @animation.aws_url
    # when showing the image within the site itself
    # we dont count that
    if params[:n]
      count = false
    end
    if count
      @animation.increaseViews
      # for the previous/next buttons
      @prevani = Animation.where( 'id < ?', @animation.id).order('id DESC').limit(1)[0]
      @nextani = Animation.where( 'id > ?', @animation.id).order('id ASC').limit(1)[0]
    end
    # when showing the thumb
    if params[:m]=="t"
      redirect = @animation.aws_thumb_url
    end
    respond_to do |format|
      format.html # view.html.erb
      format.json { render :json => @animation }
      format.png { redirect_to redirect }
      format.jpeg { redirect_to redirect }
      format.gif { redirect_to redirect }
    end
  end
  
end
