namespace :stereo do
  task :push => :environment do
    puts "Starting pushing images to DB"
    Image.destroy_all
    Image.pushToDB
    puts "Finished!"
  end
  task :revive => :environment do
    puts "Recreating entire animation dataset"
    Animation.recreateAWS
    puts "Finished!"
  end
  task :purgeBlacklisted => :environment do
    puts "Validating all animations are off-blacklist"
    Animation.purgeBlacklisted
    puts "Finished!"
  end
end