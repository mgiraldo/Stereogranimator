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
    puts "Removing stress test images"
    stuff = Animation.where(:creator => "siege")
    puts "Destroying #{stuff.length} images"
    stuff.destroy_all
    puts "Finished!"
  end
end