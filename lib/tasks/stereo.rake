namespace :stereo do
  task :push => :environment do
    puts "Starting pushing images to DB"
    Image.destroy_all
    Image.pushToDB
    puts "Finished!"
  end
end