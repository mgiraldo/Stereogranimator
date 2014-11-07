# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Stereo::Application.initialize!

Rails.logger = Logger.new(STDOUT)
Rails.logger.level = 0

# when I grow up I want to be able to send email from this app
ActionMailer::Base.smtp_settings = {
  :address        => 'smtp.sendgrid.net',
  :port           => '587',
  :authentication => :plain,
  :user_name      => ENV['SENDGRID_USERNAME'],
  :password       => ENV['SENDGRID_PASSWORD'],
  :domain         => 'herokuapp.com',
  :enable_starttls_auto => true
}
