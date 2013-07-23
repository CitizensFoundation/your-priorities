if Rails.env.production?
  module Facebooker2
    def self.load_facebooker_env
      self.configuration = {:app_id=>ENV['FACEBOOKER2_APP_ID'], :api_key=>ENV['FACEBOOKER2_API_KEY'],
                            :secret=>ENV['FACEBOOKER2_API_KEY']}
    end

    def self.load_facebooker_yaml
      self.configuration = {:app_id=>ENV['FACEBOOKER2_APP_ID'], :api_key=>ENV['FACEBOOKER2_API_KEY'],
                            :secret=>ENV['FACEBOOKER2_API_KEY']}
    end

  end
  Facebooker2.load_facebooker_env
else
  Facebooker2.load_facebooker_yaml
end
