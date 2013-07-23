class CommentsController < ApplicationController
  
  before_filter :authenticate_user!, :only => [:new, :edit, :create, :update, :destroy, :flag]
  before_filter :authenticate_admin!, :only => [:abusive, :not_abusive]
  before_filter :get_activity
  
  # GET /activities/1/comments
  # GET /activities/1/comments.xml
  def index
    if @activity.status == 'removed'
      flash[:error] = tr("That comment was deleted", "controller/comments")
      if not (user_signed_in? and current_user.is_admin?)
        redirect_to @activity.idea and return if @activity.idea
        redirect_to '/' and return
      end
    end
    @comments = @activity.comments.find(:all)
    if user_signed_in?
      @following = @activity.followings.find_by_user_id(current_user.id)
    else
      @following = nil
    end
    if user_signed_in?
      @notifications = current_user.received_notifications.unread.find(:all, :conditions => ["notifiable_id in (?) and type = 'NotificationComment'",@comments.collect{|c|c.id}])
      for n in @notifications
        n.read!
      end
    end
    @page_title = @activity.name
    respond_to do |format|
      format.html
      format.xml { render :xml => @comments.to_xml(:include => :user, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @comments.to_json(:include => :user, :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /activities/1/comments/1
  # GET /activities/1/comments/1.xml
  def show
    @comment = @activity.comments.find(params[:id])
    respond_to do |format|
      format.html
      format.xml { render :xml => @comment.to_xml(:include => :user, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @comment.to_json(:include => :user, :except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  #GET /activities/1/comments/more
  def more
    @comments = @activity.comments.published_and_abusive.by_first_created
    respond_to do |format|
      format.js {
        render :update do |page|
          update_div_name = 'activity_' + @activity.id.to_s + '_comments'
          page.replace_html update_div_name, render(:partial => "comments/show_all")
          page.insert_html :bottom, update_div_name, render(:partial => "new_inline", :locals => {:comment => Comment.new, :activity => @activity})
          page << "jQuery('#comment_content_#{@activity.id.to_s}').autoResize({extraSpace : 20});"
          page << "FB.XFBML.parse(document.getElementById('#{update_div_name}'));"
        end
      }
    end
  end
  
  #GET /activities/1/comments/1/unhide
  def unhide
    @comment = @activity.comments.find(params[:id])
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace 'comment_' + @comment.id.to_s, render(:partial => "comments/show", :locals => {:comment => @comment, :first_comment=>false})
        end
      }
    end
  end  

  # GET /activities/1/comments/new
  # GET /activities/1/comments/new.xml
  def new
    @comment = @activity.comments.new
    respond_to do |format|
      format.html # new.html.erb
      format.js {
        render :update do |page|
          page.insert_html :bottom, 'activity_' + @activity.id.to_s + '_comments', render(:partial => "new_inline", :locals => {:comment => @comment, :activity => @activity})
          page.remove 'comment_link_' + @activity.id.to_s
          page << render(:partial => "shared/javascripts_reloadable", formats: [:js])
          page['comment_content_' + @activity.id.to_s].focus    
          page << "jQuery('#comment_content_#{@activity.id.to_s}').autoResize({extraSpace : 20});"
        end        
      }
    end
  end
  
  # GET /activities/1/comments/1/edit
  def edit
    @comment = @activity.comments.find(params[:id])
    @page_title = tr("Editing comment", "controller/comments")
  end

  # POST /activities/1/comments
  # POST /activities/1/comments.xml
  def create
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
      respond_to do |format|
        format.html { 
          flash[:notice] = tr("Saved comment", "controller/comments")
          redirect_to(activity_comments_path(@activity)) 
        }
        format.js {
          render :update do |page|            
            page.insert_html :before, 'activity_' + @activity.id.to_s + '_comment_form_container', render(:partial => "comments/show", :locals => {:comment => @comment, :activity => @activity, :first_comment=>false})
            page.replace 'activity_' + @activity.id.to_s + '_comment_form_container', render(:partial => "new_inline", :locals => {:comment => Comment.new, :activity => @activity})
            page << "pageTracker._trackPageview('/goal/comment')" if current_instance.has_google_analytics?
          end     
        }     
      end
    else
      respond_to do |format|
        format.js {
          render :update do |page|
            page["comment-form-submit"].enable
            page["comment_content_"+@activity.id.to_s].focus
            for error in @comment.errors
              page.replace_html 'comment_error_'+@activity.id.to_s, error[0] + ' ' + error[1]
            end
          end
        }
        format.html { render :action => "new" }
      end
    end
  end
  
  # GET /activities/1/comments/1/flag
  # GET /activities/1/comments/1/flag
  def flag
    @comment = @activity.comments.find(params[:id])
    @comment.flag_by_user(current_user)
    respond_to do |format|
      format.html { redirect_to(comments_url) }
      format.js {
        render :update do |page|
          if current_user.is_admin?
            page.replace 'comment_' + @comment.id.to_s, render(:partial => "comments/flagged", :locals => {:comment => @comment})
          else
            page.replace 'comment_' + @comment.id.to_s, "<div class='red'>#{tr("Thanks for flagging comment", "controller/comments")}</div>".html_safe
          end
        end        
      }
    end    
  end

  # POST /activities/1/comments/1/abusive
  # POST /activities/1/comments/1/abusive
  def abusive
    @comment = @activity.comments.find(params[:id])
    @comment.abusive_reason=params[:warning_reason]
    @comment.abusive!
    respond_to do |format|
      format.html { redirect_to(comments_url) }
      format.js {
        render :update do |page|
          page.remove 'comment_flag_' + @comment.id.to_s
          page.replace 'comment_' + @comment.id.to_s, render(:partial => "comments/show", :locals => {:comment => @comment, :first_comment=>false})
        end        
      }
    end    
  end

  # POST /activities/1/comments/1/not_abusive
  # POST /activities/1/comments/1/not_abusive
  def not_abusive
    @comment = @activity.comments.find(params[:id])
    @comment.update_attribute(:flags_count, 0)
    respond_to do |format|
      format.html { redirect_to(comments_url) }
      format.js {
        render :update do |page|
          page.remove 'comment_flag_' + @comment.id.to_s
        end        
      }
    end    
  end

  # PUT /activities/1/comments/1
  # PUT /activities/1/comments/1.xml
  def update
    @comment = @activity.comments.find(params[:id])
    @page_title = tr("Editing comment", "controller/comments")
    access_denied! unless current_user.is_admin? or @comment.user_id == current_user.id
    respond_to do |format|
      if @comment.update_attributes(params[:comment])
        flash[:notice] = tr("Saved comment", "controller/comments")
        format.html { redirect_to(activity_comments_path(@activity)) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /activities/1/comments/1
  # DELETE /activities/1/comments/1.xml
  def destroy
    @comment = @activity.comments.find(params[:id])
    access_denied! unless current_user.is_admin? or @comment.user_id == current_user.id
    @comment.remove!
    respond_to do |format|
      format.html { redirect_to(comments_url) }
      format.js {
        render :update do |page|
          page.remove 'comment_' + @comment.id.to_s
        end        
      }
    end
  end
  
  protected
  def get_activity
    @activity = Activity.unscoped.find(params[:activity_id])
  end  
  
end
