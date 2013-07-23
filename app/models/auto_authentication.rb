class AutoAuthentication < ActiveRecord::Base
  belongs_to :user

  def self.create_with_secret!(user)
    secret = SecureRandom.urlsafe_base64(99)
    AutoAuthentication.create!(:secret=>secret, :user_id=>user.id)
    secret
  end

end
