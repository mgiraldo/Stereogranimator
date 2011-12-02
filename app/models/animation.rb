class Animation < ActiveRecord::Base
  def url
    "http://images.nypl.org/index.php?id=#{digitalid}&t=w"
  end
  def aws_url
    "http://s3.amazonaws.com/stereogranimator/#{filename}"
  end
  def as_json(options = { })
      h = super(options)
      h[:url] = url
      h[:aws_url]   = aws_url
      h[:url] = url
      h
  end
end
