class InboxController < ApplicationController

  before_filter :authenticate_user!
  
  def notifications
    @page_title =  tr("Your notifications", "controller/inbox")
    @notifications = current_user.received_notifications.active.by_recently_created.find(:all, :include => [:notifiable]).paginate :page => params[:page], :per_page => params[:per_page]
    @rss_url = url_for(:only_path => false, :controller => "rss", :action => "your_notifications", :format => "rss", :c => current_user.rss_code)
    respond_to do |format|
      format.html
      format.xml { render :xml => @notifications.to_xml(:include => [:notifiable], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @notifications.to_json(:include => [:notifiable], :except => NB_CONFIG['api_exclude_fields']) }
    end
    if request.format == 'html'
      for n in @notifications
        n.read! if n.class != NotificationMessage and n.unread?
      end    
    end
  end  
  
end
