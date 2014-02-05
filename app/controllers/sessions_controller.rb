class SessionsController < Devise::SessionsController
  skip_before_filter :check_idea
  skip_before_filter :check_referral
  skip_before_filter :check_suspension
  skip_before_filter :check_blast_click

  def create
    if request.format == 'js' && params[:region] && params[:region] == 'inline'
      resource = warden.authenticate(auth_options)
      Rails.logger.debug(auth_options.inspect)
      if warden.authenticated?
        sign_in(resource)
        current_user.remember_me!
        current_user.activate! if not current_user.active?
        path = after_sign_in_path_for(resource)
        render :update do |page|
          page.redirect_to path
        end
      else
        render partial: 'sessions/login_failed'
      end
    else
      super
    end

    # check if they were trying to endorse/oppose an idea
    if request.format == 'js' && session[:idea_id]
      @idea = Idea.find(session[:idea_id])
      @value = session[:value].to_i
      if @idea
        if @value == 1
          @idea.endorse(current_user,request,@referral)
        else
          @idea.oppose(current_user,request,@referral)
        end
      end
      session[:idea_id] = nil
      session[:value] = nil
    end
  end

  protected

  # disable the "you have signed in/out" flash notices from Devise
  def clear_signin_signout_flash
    flash.delete(:notice) if flash.keys.include?(:notice)
  end
end
