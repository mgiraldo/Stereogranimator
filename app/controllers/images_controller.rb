class ImagesController < ApplicationController
  # GET /getimagedata/digitalid
  def getimagedata
    url = params[:url]
    # remove the https (flickr doesnt like heroku in https)
    url.gsub!(/https:/, 'http:') if ENV['RAILS_ENV'] == 'production'
    puts(url)
    im = Magick::Image.read(url).first
    im.background_color = "none"
    # test for width (for HQ images)
    if (im.columns > 800)
      im = im.resize_to_fit(800)
    end

    if (im.rows > 600)
      im = im.resize_to_fit(800,600)
    end

    im = im.rotate(params[:r].to_f)
    str = Base64.encode64(im.to_blob{self.format = "JPEG"})
    output = {
      "width" => im.columns,
      "height" => im.rows,
      "data" => "data:image\/jpeg;base64," + str
    }
#    https://images.nypl.org/index.php?id="+index+"&t=w
    respond_to do |format|
      format.json { render :json => output }
      format.jpeg { render :plain => im.to_blob{self.format = "JPEG"}, :status => 200, :type => 'image/jpg' }
    end
  end

  # GET /getpixels/digitalid
  def getpixels
    url = params[:url]
    # remove the https (flickr doesnt like heroku in https)
    url = url.gsub(/https:/, 'http:')
    im = Magick::Image.read(url).first
    # test for width (for HQ images)
    if (im.columns > 800)
      im = im.resize_to_fit(800)
    end

    if (im.rows > 600)
      im = im.resize_to_fit(800,600)
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
