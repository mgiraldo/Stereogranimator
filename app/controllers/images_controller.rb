class ImagesController < ApplicationController
  # GET /getimagedata/digitalid
  def getimagedata
    url = "http://images.nypl.org/index.php?id=#{params[:url]}&t=w"
    im = Magick::Image.read(url).first
    im.background_color = "none"
    im = im.rotate(params[:r].to_f)
    str = ActiveSupport::Base64.encode64(im.to_blob{self.format = "JPEG"})
    output = {
      "width" => im.columns,
      "height" => im.rows,
      "data" => "data:image\/jpeg;base64," + str
    }
#    http://images.nypl.org/index.php?id="+index+"&t=w
    respond_to do |format|
      format.html { render :json => "#{params[:callback]}(#{output.to_json});" }
      format.jpeg { render :text => im.to_blob{self.format = "JPEG"}, :status => 200, :type => 'image/jpg' }
    end
  end
  
  # GET /getimagedata/digitalid
  def getpixels
    url = "http://images.nypl.org/index.php?id=#{params[:digitalid]}&t=w"
    im = Magick::Image.read(url).first

    respond_to do |format|
      format.jpeg { render :text => im.to_blob{self.format = "JPEG"}, :status => 200, :type => 'image/jpg' }
    end
    
  end
  
end
