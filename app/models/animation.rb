class Animation < ActiveRecord::Base
  def url
    "http://images.nypl.org/index.php?id=#{digitalid}&t=w"
  end
end
