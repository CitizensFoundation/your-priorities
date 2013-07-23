class FollowingDiscussionsController < ApplicationController

  before_filter :authenticate_user!
  before_filter :get_activity

  # GET /activities/1/followings
  # GET /activities/1/followings.xml
  def index
    if @activity.status == 'removed'
      flash[:error] = tr("That comment was deleted", "controller/discussions")
      if not (user_signed_in? and current_user.is_admin?)
        redirect_to @activity.idea and return if @activity.idea
        redirect_to '/' and return
      end
    end
    @comments = @activity.comments.find(:all)
    if user_signed_in?
      @notifications = current_user.received_notifications.unread.find(:all, :conditions => ["notifiable_id in (?) and type = 'NotificationComment'",@comments.collect{|c|c.id}])
      for n in @notifications
        n.read!
      end
    end
    @page_title = @activity.name
    respond_to do |format|
      format.html
      format.xml { render :xml => @followings.to_xml(:include => :user, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @followings.to_json(:include => :user, :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /activities/1/followings/new
  def new
    @following = @activity.comments.new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # POST /activities/1/followings
  def create
    if @following = @activity.followings.find_or_create_by_user_id(current_user.id)
      ActivityDiscussionFollowingNew.create(:user => current_user, :activity => @activity)
      respond_to do |format|
        format.html { 
          flash[:notice] = tr("You will now be notified when others add to this discussion", "controller/discussions")
          redirect_to(activity_comments_path(@activity)) 
        }
        format.js {
          render :update do |page|            
            if params[:region] == 'activity_show'
              page.replace 'activity_add_' + @activity.id.to_s, render(:partial => "shared/follow_icons", :locals => {:activity => @activity, :following => @following})
            end
          end     
        }     
      end
    end
  end

  # DELETE /activities/1/followings/1
  def destroy
    @following = @activity.followings.find(params[:id])
    access_denied! unless current_user.is_admin? or @following.user_id == current_user.id
    @following.destroy
    respond_to do |format|
      format.html { redirect_to(activity_comments_url(@activity)) }
      format.js {
        render :update do |page|
          if params[:region] == 'activity_show'
            page.redirect_to activity_comments_url(@activity)
            #page.replace 'activity_add_' + @activity.id.to_s, render(:partial =>"shared/follow_icons", :locals => {:activity => @activity, :following => nil})
          end          
        end     
      }
    end
  end
  
  protected
  def get_activity
    @activity = Activity.find(params[:activity_id])
  end  

end
