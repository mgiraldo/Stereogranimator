namespace :stereo do
  task :push => :environment do
    puts "Deleting existing images"
    Image.destroy_all
    puts "Starting pushing images to DB"
    Image.pushToDB
    puts "Finished!"
  end

  task :revive => :environment do
    puts "Recreating entire animation dataset files"
    Animation.recreateAWS
    puts "Finished!"
  end

  task :purgeBlacklisted => :environment do
    puts "Validating all animations are off-blacklist"
    Animation.purgeBlacklisted
    puts "Finished!"
  end

  task :purgeSiege => :environment do
    # puts "Removing stress test images"
    # count = Animation.select('COUNT(id) as total').where(:creator => "siege").map(&:total)[0].to_i
    # puts "Destroying #{count} images"
    # puts "Destroying from AWS"
    # puts "Assembling image list"
    # awsfiles = Animation.select('filename').where(:creator => "siege").map(&:filename)
    # puts "Commit to AWS"
    # s3 = AWS::S3.new
    # bucket = s3.buckets['stereo.nypl.org']
    # awsfiles.each do |f|
      # if f != nil && f != ""
        # obj = bucket.objects[f]
        # obj.delete()
        # obj = bucket.objects["t_" + f]
        # obj.delete()
      # end
    # end
    # puts "Destroying from DB"
    # stuff = Animation.where(:creator => "siege")
    # stuff.destroy_all
    # puts "Finished!"
    puts "Removing stress test images"
    stuff = Animation.where(:creator => "siege")
    puts "Destroying #{stuff.length} images"
    stuff.destroy_all
    puts "Finished!"
  end

  task :process_takedowns => :environment do
    puts "Processing Flickr takedowns"
    Animation.process_takedowns
    puts "Done!"
  end

end