class Animation < ActiveRecord::Base
  def url
    "http://images.nypl.org/index.php?id=#{digitalid}&t=w"
  end
  def aws_url
    "http://s3.amazonaws.com/stereogranimator/#{filename}"
  end
end
