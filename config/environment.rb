# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Stereo::Application.initialize!

Rails.logger = Logger.new(STDOUT)
Rails.logger.level = 0
Mime::Type.register "image/jpg", :jpg
=begin
# when I grow up I want to be able to send email from this app
config.action_mailer.delivery_method = :smtp
config.action_mailer.raise_delivery_errors = true

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
=end
