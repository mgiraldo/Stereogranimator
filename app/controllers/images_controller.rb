class ImagesController < ApplicationController
  # GET /getimagedata/digitalid
  def getimagedata
    url = params[:url]
    im = Magick::Image.read(url).first
    im.background_color = "none"
    # test for width (for HQ images)
    if (im.columns > 800)
      im = im.resize_to_fit(800)
    end
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
  
  # GET /getpixels/digitalid
  def getpixels
    url = params[:url]
    im = Magick::Image.read(url).first
    # test for width (for HQ images)
    if (im.columns > 800)
      im = im.resize_to_fit(800)
    end

    respond_to do |format|
      format.jpeg { render :text => im.to_blob{self.format = "JPEG"}, :status => 200, :type => 'image/jpg' }
    end
    
  end
  
  def verifyPhoto
    respond_to do |format|
      format.json { render :json => Image.verifyFlickrPhoto(params[:id]).to_json }
    end
  end
  
  def test
    render :json => flickr.photosets.getInfo(:photoset_id => "72157604192771132")
  end
  
end
