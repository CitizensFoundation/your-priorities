class FacebookController < ApplicationController

  before_filter :authenticate_user!
  protect_from_forgery :except => :multiple

  def invite
    @page_title = tr("Invite your Facebook friends to join {instance_name}", "controller/facebook", :instance_name => current_instance.name)
    @user = User.find(current_user.id)
    @facebook_contacts = @user.contacts.active.facebook.collect{|c|c.facebook_uid}
    if current_facebook_user_if_on_facebook
      app_users = current_facebook_user.friends
      if app_users.any?
        count = 0
        @users = User.active.find(:all, :conditions => ["facebook_uid in (?)",app_users.collect{|u|u.id}.uniq.compact])
        for user in @users
          unless @facebook_contacts.include?(user.facebook_uid)
            count += 1
            current_user.follow(user)
            @facebook_contacts << user.facebook_uid
          end
        end
      end
    end
  end

  # POST /facebook/multiple
  def multiple
    @user = User.find(current_user.id)
    if not params[:ids]
      redirect_to :controller => "network", :action => "find"
      return
    end
    @fb_users = current_facebook_user.friends
    success = 0
    @fb_users.each do |fb_user|
      next unless params[:ids].include?(fb_user.id.to_s)
      @contact = @user.contacts.create(:name => fb_user.name, :facebook_uid => fb_user.id, :is_from_realname => 1)
      if @contact
        success += 1
        @contact.invite!
        @contact.send!
      end
    end
    if success > 0
      flash[:notice] = tr("Invited {number} of your Facebook friends", "controller/facebook", :number => success)
    end
    redirect_to invited_user_contacts_path(current_user)
  end
  
end
