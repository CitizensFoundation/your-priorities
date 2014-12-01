class SettingsController < ApplicationController
  
  before_filter :authenticate_user!
  #before_filter :authenticate_root!, :only=>["signups"]
  before_filter :get_user

  # GET /settings
  def index
    @sub_instances = SubInstance.find(:all, :conditions => "is_optin = true and status = 'active' and id <> 3")
    @page_title = tr("Your {instance_name} settings", "controller/settings", :instance_name => current_instance.name)
  end

  # PUT /settings
  def update
    respond_to do |format|
      params[:user].each do |attribute, value|
        @user.update_attribute(attribute.to_sym, value)
      end
      flash[:notice] = tr("Saved your settings", "controller/settings")
      format.html {
        redirect_to("/")
      }
    end
  end

  # GET /settings/signups
  def signups
    @page_title = tr("Your email notifications", "controller/settings", :instance_name => current_instance.name)
    @rss_url = url_for(:only_path => false, :controller => "rss", :action => "your_notifications", :format => "rss", :c => current_user.rss_code)
    @sub_instances = SubInstance.find(:all, :conditions => "status = 'active'")
  end

  # GET /settings/picture
  def picture
    @page_title = tr("Your picture", "controller/settings")
  end

  def picture_save
    @user = current_user
    respond_to do |format|
      if @user.update_attributes(params[:user])
        ActivityUserPictureNew.create(:user => @user)   
        flash[:notice] = tr("Picture uploaded successfully", "controller/settings")
        format.html { redirect_to(:action => :picture) }
      else
        format.html { render :action => "picture" }
      end
    end
  end
    
  # GET /settings/delete
  def delete
    @page_title = tr("Delete your {instance_name} account", "controller/settings", :instance_name => current_instance.name)
  end

  # DELETE /settings
  def destroy
    @user.remove!
    self.current_user.forget_me
    cookies.delete :auth_token
    reset_session    
    Thread.current[:current_user] = nil
    flash[:notice] = tr("Your account was deleted. Good bye!", "controller/settings")
    redirect_to "/" and return
  end

  private
  def get_user
    @user = User.find(current_user.id)
  end

end
