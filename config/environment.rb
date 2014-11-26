# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Stereo::Application.initialize!

Rails.logger = Logger.new(STDOUT)
Rails.logger.level = 0

Mail.defaults do
  delivery_method :smtp, {
    :address => 'smtp.sendgrid.net',
    :port => '587',
    :domain => 'herokuapp.com',
    :user_name => ENV['SENDGRID_USERNAME'],
    :password => ENV['SENDGRID_PASSWORD'],
    :authentication => :plain,
    :enable_starttls_auto => true
  }
end
