class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "railslearning.developer0919@gmail.com")
  layout "mailer"
end
