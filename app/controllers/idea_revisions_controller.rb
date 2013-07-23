class IdeaRevisionsController < ApplicationController

  before_filter :get_idea
  before_filter :authenticate_user!, :except => [:show, :clean]
  before_filter :authenticate_admin!, :only => [:destroy, :update, :edit]

  def index
    redirect_to @idea
    return
  end

  def show
    #if @point.is_removed?
    #  flash[:error] = tr("That point was deleted", "controller/revisions")
    #  redirect_to @point.idea
    #  return
    #end    
    @revision = @idea.idea_revisions.find(params[:id])
    @page_title = tr("{user_name} revision of {idea_name}", "controller/revisions", :user_name => @revision.user.name.possessive, :idea_name => @revision.name)
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  def clean
    @revision = @idea.idea_revisions.find(params[:id])
    @page_title = tr("{user_name} revision of {idea_name}", "controller/revisions", :user_name => @revision.user.name.possessive, :idea_name => @revision.name)
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  def new
    @revision = @idea.idea_revisions.new
    @revision.name = @idea.name
    @revision.description = @idea.description
    @page_title = tr("Revise {idea_name}", "controller/revisions", :idea_name => @idea.name)    
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def edit
    @revision = @idea.idea_revisions.find(params[:id])
  end

  def create
    @revision = @idea.idea_revisions.new(params[:idea_revision])
    @revision.user = current_user
    respond_to do |format|
      if @revision.save
        @revision.publish!
        # this is all to add a comment with their note
        if params[:comment] and params[:comment][:content] and params[:comment][:content].length > 0
          activities = Activity.find(:all, :conditions => ["user_id = ? and type like 'ActivityIdeaRevision%' and created_at > '#{Time.now-5.minutes}'",current_user.id], :order => "created_at desc")
          if activities.any?
            activity = activities[0]
            @comment = activity.comments.new(params[:comment])
            @comment.user = current_user
            @comment.request = request
            if activity.idea
              # if this is related to a idea, check to see if they endorse it
              e = activity.idea.endorsements.active_and_inactive.find_by_user_id(@comment.user.id)
              @comment.is_endorser = true if e and e.is_up?
              @comment.is_opposer = true if e and e.is_down?
            end
            @comment.save(:validate => false)            
          end
        end
        flash[:notice] = tr("Revised {idea_name}", "controller/revisions", :idea_name => @idea.name)
        format.html { redirect_to(@idea) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def update
    @revision = @idea.idea_revisions.find(params[:id])
    respond_to do |format|
      if @revision.update_attributes(params[:revision])
        flash[:notice] = tr("Revised {idea_name}", "controller/revisions", :idea_name => @idea.name)
        format.html { redirect_to(@revision) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    @revision = @idea.idea_revisions.find(params[:id])
    flash[:notice] = tr("Deleted revision of {idea_name}", "controller/revisions", :idea_name => @idea.name)
    @revision.destroy

    respond_to do |format|
      format.html { redirect_to(revisions_url) }
      format.xml  { head :ok }
    end
  end
  
  protected
  def get_idea
    @idea = Idea.find(params[:idea_id])
  end
  
end
