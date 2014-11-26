$twitter_client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV['Twitter_Consumer_KEY']
  config.consumer_secret     = ENV['Twitter_Consumer_SECRET']
  config.access_token        = ENV['Twitter_Access_KEY']
  config.access_token_secret = ENV['Twitter_Access_SECRET']
end