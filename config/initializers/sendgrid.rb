if Rails.env.production?
  if ENV['SENDGRID_USERNAME']
    ActionMailer::Base.smtp_settings = {
        :address        => 'smtp.sendgrid.net',
        :port           => '587',
        :authentication => :plain,
        :user_name      => ENV['SENDGRID_USERNAME'],
        :password       => ENV['SENDGRID_PASSWORD'],
        :domain         => 'heroku.com',
        :enable_starttls_auto => true
    }
    if ENV['SENT_MAIL_BCC_EMAIL']
      class ProductionMailInterceptor
        def self.delivering_email(message)
          message.bcc = ENV['SENT_MAIL_BCC_EMAIL']
        end
      end

      Mail.register_interceptor(ProductionMailInterceptor)
    end
  end
else
  ActionMailer::Base.smtp_settings = {
      :address              => "localhost",
      :enable_starttls_auto => false
  }

  class DevelopmentMailInterceptor
    def self.delivering_email(message)
      message.subject = "#{message.to} #{message.subject}"
      message.to = "#{ENV['USER']}@localhost"
    end
  end

  Mail.register_interceptor(DevelopmentMailInterceptor)
end
