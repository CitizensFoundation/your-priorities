class AdminController < ApplicationController
  
  before_filter :authenticate_admin!
  before_filter :authenticate_root!, :only=>[:sub_instances, :master_statistics, :picture_save, :picture, :buddy_icon_save, :buddy_icon]


  def statistics
    @ideas_counts_per_day = Idea.count(:order => 'DATE(created_at) DESC', :group => ["DATE(created_at)"])
    @points_counts_per_day = Point.count(:order => 'DATE(created_at) DESC', :group => ["DATE(created_at)"])
    @users_counts_per_day = User.count(:order => 'DATE(created_at) DESC', :group => ["DATE(created_at)"])
    @comments_counts_per_day = Comment.count(:order => 'DATE(created_at) DESC', :group => ["DATE(created_at)"])
  end

  def master_statistics
    @ideas_counts_per_day = Idea.unscoped.count(:order => 'DATE(created_at) DESC', :group => ["DATE(created_at)"])
    @points_counts_per_day = Point.unscoped.count(:order => 'DATE(created_at) DESC', :group => ["DATE(created_at)"])
    @users_counts_per_day = User.unscoped.count(:order => 'DATE(created_at) DESC', :group => ["DATE(created_at)"])
    @comments_counts_per_day = Comment.unscoped.count(:order => 'DATE(created_at) DESC', :group => ["DATE(created_at)"])
    @sub_instance_count_per_day = SubInstance.unscoped.count(:order => 'DATE(created_at) DESC', :group => ["DATE(created_at)"])
  end

  def sub_instances
    @sub_instances = SubInstance.all
    @sub_instances = @sub_instances.sort_by {|i| i.ideas.count}.reverse
  end

  def all_flagged
    @all = [] 
    @all += Idea.published.flagged
    @all += Point.published.flagged
    @all += Comment.published.flagged
    @all = @all.sort_by {|s| s.created_at}
    @page_title = tr("All Flagged Content", "controller/admin")
  end

  def random_user
    if User.adapter == 'postgresql'
      users = User.find(:all, :conditions => "status = 'active'", :order => "RANDOM()", :limit => 1)
    else
      users = User.find(:all, :conditions => "status = 'active'", :order => "RANDOM()", :limit => 1)
    end
    sign_in users[0]
    flash[:notice] = tr("You are now logged in as {user_name}", "controller/admin", :user_name => users[0].name)
    redirect_to users[0]    
  end

  def picture
    @page_title = tr("Change logo for {instance_name}", "controller/admin", :instance_name => current_instance.name)
  end

  def picture_save
    @instance = current_instance
    respond_to do |format|
      @instance = unfrozen_instance(@instance)
      if @instance.update_attributes(params[:instance])
        flash[:notice] = tr("Picture uploaded successfully", "controller/admin")
        format.html { redirect_to(:action => :picture) }
      else
        format.html { render :action => "picture" }
      end
    end
  end

  def buddy_icon
    @page_title = tr("Change buddy icon for {instance_name}", "controller/admin", :instance_name => current_instance.name)
  end

  def buddy_icon_save
    @instance = current_instance
    respond_to do |format|
      @instance = unfrozen_instance(@instance)
      if @instance.update_attributes(params[:instance])
        flash[:notice] = tr("Picture uploaded successfully", "controller/admin")
        format.html { redirect_to(:action => :buddy_icon) }
      else
        format.html { render :action => "buddy_icon" }
      end
    end
  end  

end
