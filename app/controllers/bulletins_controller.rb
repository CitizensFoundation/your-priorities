class BulletinsController < ApplicationController
  
  before_filter :authenticate_user!, :only => [:new_inline,:create]
  
  def new_inline
    @activity = ActivityBulletinNew.create(:user => current_user)
    @comment = @activity.comments.new
    respond_to do |format|
      format.html # new.html.erb
      format.js {
        render :update do |page|
          page.select('#activity_' + @activity.id.to_s).each { |item| item.remove }
          page.select('#activity_' + @activity.id.to_s + '_comments').each { |item| item.remove }                     
          page.insert_html :top, 'activities', render(:partial => "activities/show", :locals => {:activity => @activity, :suffix => "_noself"})
          page.insert_html :bottom, 'activity_' + @activity.id.to_s + '_comments', render(:partial => "comments/new_inline", :locals => {:comment => Comment.new, :activity => @activity})
          #page.remove 'comment_link_' + @activity.id.to_s
          #page.replace_html 'comment_link', "<b>Add a comment</b>"
          page['comment_content_' + @activity.id.to_s].focus     
        end        
      }
    end    
  end

  def create
    params[:activity] ||= {}
    params[:activity][:user_id] = current_user.id
    if params[:activity][:other_user_id] # this is a post to another person's profile
      @activity = ActivityBulletinProfileNew.create(:user => User.find(params[:activity][:other_user_id]), :other_user => current_user)
      ActivityBulletinProfileAuthor.create(:activity => @activity, :user => current_user, :other_user => @activity.user, :is_user_only => true)
    else
      @activity = ActivityBulletinNew.create(params[:activity])
    end
    @comment = @activity.comments.new(params[:comment])
    @comment.user = current_user
    @comment.request = request
    if @activity.idea
      # if this is related to a idea, check to see if they endorse it
      e = @activity.idea.endorsements.active_and_inactive.find_by_user_id(@comment.user.id)
      @comment.is_endorser = true if e and e.is_up?
      @comment.is_opposer = true if e and e.is_down?
    end    
    if @comment.save
      @activity.send_notification if @activity.class == ActivityBulletinProfileNew
      @activity.reload
      respond_to do |format|
        format.html { 
            if @activity.idea
              redirect_to @activity.idea
            else
              redirect_to :controller => "feed", :action => "your_network_activities"
            end
          }
        format.js {
          render :update do |page|
            page.insert_html :top, 'new_activities', render(:partial => "activities/show", :locals => {:activity => @activity, :suffix => ""})
#            page["bulletin-form-submit"].enable  
            page["bulletin_content"].focus()
#            page["bulletin_content"].clear()
            page << "$('textarea#bulletin_content').val('');"
            page << "pageTracker._trackPageview('/goal/comment')" if current_instance.has_google_analytics?
          end        
        }        
      end
    else
      @activity.destroy
      respond_to do |format|
        format.js {
          render :update do |page|
 #           page["bulletin-form-submit"].enable
            page["bulletin_content"].focus
            for error in @comment.errors
              page.replace_html 'bulletin_error', error[0] + ' ' + error[1]
            end
          end
        }
      end
    end    
        
  end
  
end
