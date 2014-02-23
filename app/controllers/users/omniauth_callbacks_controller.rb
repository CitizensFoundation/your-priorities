class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def facebook
    Rails.logger.info "-------------------------------------------- FACEBOOK LOGIN ---------------------------------------------"
    Rails.logger.info request.env["omniauth.auth"]
    session["omniauth_data"] = {
      email: request.env["omniauth.auth"][:info][:email],
      facebook_id: request.env["omniauth.auth"][:uid],
      provider: "Facebook",
    }

    if @user = User.find_for_facebook_oauth(request.env["omniauth.auth"])
      @user.activate! unless @user.active?
      sign_in_and_redirect @user, event: :authentication
    elsif @user = User.find_by_email(request.env["omniauth.auth"][:info][:email])
      session["omniauth_data"][:email] = @user.email
      redirect_to new_user_session_url
    else
      session["omniauth_data"][:new_user] = true
      redirect_to new_user_registration_url
    end
  end

  def failure
    Rails.logger.error "-------------------------------------------- FACEBOOK LOGIN FAILURE ---------------------------------------------"
    Rails.logger.info request.env["omniauth.auth"]
    Rails.logger.info params.inspect
    Rails.logger.info request.inspect

    #flash[:error] = tr("Error signing in - please try again","here")
    redirect_to "/"
  end
end
