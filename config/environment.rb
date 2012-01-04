# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Stereo::Application.initialize!

=begin
config.action_mailer.delivery_method = :smtp
config.action_mailer.raise_delivery_errors = true

ActionMailer::Base.smtp_settings = {
  :address  => "smtp.someserver.net",
  :port  => 25,
  :user_name  => "someone@someserver.net",
  :password  => "mypass",
  :authentication  => :login
}
=end