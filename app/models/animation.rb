class Animation < ActiveRecord::Base
  def url
    "http://images.nypl.org/index.php?id=#{digitalid}&t=w"
  end
  def aws_url
    "http://s3.amazonaws.com/stereogranimator/#{filename}"
  end
  def aws_thumb_url
    "http://s3.amazonaws.com/stereogranimator/t_#{filename}"
  end
  def nypl_url
    "http://digitalgallery.nypl.org/nypldigital/dgkeysearchdetail.cfm?&imageID=#{digitalid}"
  end
  def as_json(options = { })
      h = super(options)
      h[:url] = url
      h[:aws_url]   = aws_url
      h[:aws_thumb_url]   = aws_thumb_url
      h[:redirect] = "/share/#{id}"
      h
  end
end
