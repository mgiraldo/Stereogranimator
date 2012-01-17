namespace :stereo do
  task :push => :environment do
    puts "Starting pushing images to DB - " + Date.now
    Image.destroy_all
    Image.pushToDB
    puts "Finished! - " + Date.now
  end
end