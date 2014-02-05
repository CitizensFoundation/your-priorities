class FeedController < ApplicationController

  before_filter :authenticate_user!, :except => [:index, :top, :top_feed, :discussions, :points, :activities, :capitals, :official, :changes, :changes_voting, :changes_activity, :ads, :videos, :comments, :your_discussions, :your_idea_discussions, :your_network_discussions, :your_ideas_created_discussions]
  before_filter :check_for_user, :only => [:your_discussions, :your_idea_discussions, :your_network_discussions, :your_ideas_created_discussions]

  caches_action :top, :discussions, :activities, :points,
                :if => proc {|c| c.do_action_cache? },
                :cache_path => proc {|c| c.action_cache_path},
                :expires_in => 2.minutes

  before_filter :setup_filter_dropdown

  def index
    redirect_to :action => "activities"
    return
  end

  def videos
    redirect_to :controller => "about"
    return
  end

  def discussions
    @page_title = tr("What everyone is discussing at {instance_name}", "controller/feed", :instance_name => current_instance.name)
    @rss_url = url_for(:only_path => false, :action => "comments", :format => "rss")
    if @current_instance.users_count > 5000 # only show the last 7 days worth
      @activities = Activity.active.discussions.for_all_users.last_seven_days.by_recently_updated.paginate :page => params[:page], :per_page => 15
    else
      @activities = Activity.active.discussions.for_all_users.by_recently_updated.paginate :page => params[:page], :per_page => 15
    end
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'activities/discussions_widget_small')) + "');" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def comments
    @page_title = tr("Latest comments at {instance_name}", "controller/feed", :instance_name => current_instance.name)
    @comments = Comment.published.last_three_days.by_recently_created.find(:all, :include => :activity).paginate :page => params[:page]
    respond_to do |format|
      format.rss { render :template => "rss/comments" }
      format.xml { render :xml => @comments.to_xml(:include => :user, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @comments.to_json(:include => :user, :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def points
    @page_title = tr("Latest activity for points at {instance_name}", "controller/feed", :instance_name => current_instance.name)
    @activities = Activity.active.points_and_docs.for_all_users.paginate :page => params[:page]
    @rss_url = url_for(:only_path => false, :format => "rss")
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.rss { render :template => "rss/activities" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def activities
    @page_title = tr("Everything happening at {instance_name}", "controller/feed", :instance_name => current_instance.name)
#    if @current_instance.users_count > 5000 # only show the last 7 days worth
#      @activities = Activity.active.for_all_users.last_seven_days.by_recently_created.paginate :page => params[:page]
#    else
     @activities = Activity.active.for_all_users.by_recently_created.paginate :page => params[:page]
#    end
    @rss_url = url_for(:only_path => false, :format => "rss")
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.rss { render :template => "rss/activities" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def top
    @page_title = tr("Top Feed at {sub_instance_name}", "controller/feed", :sub_instance_name => current_sub_instance.name)
    @activities = Activity.active.top.for_all_users.paginate :page => params[:page]
    @rss_url = url_for(:only_path => false, :format => "rss")
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.rss { render :template => "rss/activities" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def top_feed
    @page_title = tr("Top Feed at {sub_instance_name}", "controller/feed", :sub_instance_name => current_sub_instance.name)
    if params[:idea_id]
      @idea = Idea.unscoped.find(params[:idea_id])
      if params[:only_comments]
        @activities = @idea.activities.active.top_discussions.for_all_users.paginate :page => params[:page]
      else
        @activities = @idea.activities.active.top.for_all_users.paginate :page => params[:page]
      end
    else
      @activities = Activity.active.top.for_all_users.paginate(:page => params[:page])
    end

    @rss_url = url_for(:only_path => false, :format => "rss")
    respond_to do |format|
      format.js
      format.html { render :action => "activity_list" }
      format.rss { render :template => "rss/activities" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def capital
    @page_title = tr("{currency_name} at {sub_instance_name}", "controller/feed", :sub_instance_name => current_sub_instance.name, :currency_name => current_instance.currency_name.titleize)
    @activities = Activity.active.for_all_users.capital.by_recently_created.paginate :page => params[:page]
    @rss_url = url_for(:only_path => false, :format => "rss")
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.rss { render :template => "rss/activities" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def changes
    @page_title = tr("Acquisition proposals", "controller/feed", :sub_instance_name => current_sub_instance.name)
    @changes = Change.suggested.by_recently_created.paginate :page => params[:page]
    respond_to do |format|
      format.html { render :action => "change_list" }
      format.xml { render :xml => @changes.to_xml(:include => [:idea, :new_idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @changes.to_json(:include => [:idea, :new_idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def changes_voting
    @page_title = tr("Voting results on acquisition proposals", "controller/feed", :instance_name => current_instance.name)
    @changes = Change.voting.by_recently_started.paginate :page => params[:page]
    respond_to do |format|
      format.html { render :action => "change_list" }
      format.xml { render :xml => @changes.to_xml(:include => [:idea, :new_idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @changes.to_json(:include => [:idea, :new_idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def changes_activity
    @page_title = tr("M&A activity at {sub_instance_name}", "controller/feed", :sub_instance_name => current_sub_instance.name)
    @activities = Activity.active.for_all_users.changes.by_recently_created.paginate :page => params[:page]
    @rss_url = url_for(:only_path => false, :format => "rss")
    respond_to do |format|
      format.html { render :action => "changes_activity" }
      format.rss { render :template => "rss/activities" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def your_activities
    @page_title = tr("What are you doing at {sub_instance_name}?", "controller/feed", :sub_instance_name => current_sub_instance.name)
    @activities = current_user.activities.active.for_all_users.by_recently_created.paginate :page => params[:page]
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def your_capital
    @page_title = tr("Your {currency_name} at {sub_instance_name}", "controller/feed", :sub_instance_name => current_sub_instance.name, :currency_name => current_instance.currency_name.downcase)
    @activities = current_user.activities.active.capital.for_all_users.by_recently_created.paginate :page => params[:page]
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def your_changes
    @page_title = tr("Your M&A activity at {sub_instance_name}", "controller/feed", :sub_instance_name => current_sub_instance.name)
    @activities = current_user.activities.active.changes.for_all_users.by_recently_created.paginate :page => params[:page]
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def your_points
    @page_title = tr("Your points activity at {sub_instance_name}", "controller/feed", :sub_instance_name => current_sub_instance.name)
    # this needs some work
    @activities = current_user.activities.active.points_and_docs.by_recently_created.paginate :page => params[:page]
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def your_discussions
    @page_title = tr("Discussions you're following at {sub_instance_name}", "controller/feed", :sub_instance_name => current_sub_instance.name)
    @activities = @user.following_discussion_activities.active.by_recently_updated.paginate :page => params[:page], :per_page => 15
    @rss_url = url_for(:only_path => false, :controller => "rss", :action => "your_comments", :format => "rss", :c => @user.rss_code)
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'activities/discussions_widget_small')) + "');" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
    if user_signed_in? and request.format == 'html' and current_user.unread_notifications_count > 0
      for n in current_user.received_notifications.comments.unread.all
        begin
          n.read!
        rescue
          Rails.logger.error("Can't set message to read #{n.inspect}")
        end
      end
    end
  end

  # doesn't include activities that followers are commenting on
  def your_followers_activities
    @page_title = tr("Your followers' activity at {sub_instance_name}", "controller/feed", :sub_instance_name => current_sub_instance.name)
    @activities = Activity.active.for_all_users.by_recently_created.paginate :conditions => ["user_id in (?)",current_user.followers.collect{|e|e.user_id}.uniq.compact], :page => params[:page]
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # doesn't include activities that followers are commenting on
  def your_followers_discussions
    @page_title = tr("Discussions your followers are participating in", "controller/feed", :instance_name => current_instance.name)
    @activities = Activity.active.discussions.by_recently_created.paginate :conditions => ["user_id in (?)",current_user.followers.collect{|e|e.user_id}.uniq.compact], :page => params[:page], :per_page => 15
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def your_followers_points
    @page_title = tr("Points from your followers", "controller/feed", :sub_instance_name => current_sub_instance.name)
    @activities = Activity.active.points_and_docs.paginate :conditions => ["user_id in (?)",current_user.followers.collect{|e|e.user_id}.uniq.compact], :page => params[:page]
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def your_followers_capital
    @page_title = tr("Your followers' {currency_name}", "controller/feed", :sub_instance_name => current_sub_instance.name, :currency_name => current_instance.currency_name.downcase)
    @activities = Activity.active.capital.by_recently_created.paginate :conditions => ["user_id in (?)",current_user.followers.collect{|e|e.user_id}.uniq.compact], :page => params[:page]
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def your_followers_changes
    @page_title = tr("M&A activity from your followers", "controller/feed", :sub_instance_name => current_sub_instance.name)
    @activities = Activity.active.changes.by_recently_created.paginate :conditions => ["user_id in (?)",current_user.followers.collect{|e|e.user_id}.uniq.compact], :page => params[:page]
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # doesn't include activities that followers are commenting on
  def your_network_activities
    @page_title = tr("What's happening in your {sub_instance_name}?", "controller/feed", :sub_instance_name => current_sub_instance.name)
    if current_following_ids.empty?
      @activities = Activity.active.for_all_users.by_recently_created.paginate :conditions => "user_id = #{current_user.id.to_s}", :page => params[:page]
    else
      @activities = Activity.active.for_all_users.by_recently_created.paginate :conditions => "user_id in (#{current_user.id.to_s},#{current_following_ids.join(',')})", :page => params[:page]
    end
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # doesn't include activities that followers are commenting on
  def your_network_discussions
    @page_title = tr("Discussions in your network", "controller/feed", :sub_instance_name => current_sub_instance.name)
    if @user.followings_count == 0
      @activities = Activity.active.discussions.by_recently_created.paginate :conditions => "user_id = #{@user.id.to_s}", :page => params[:page], :per_page => 15
    else
      @activities = Activity.active.discussions.by_recently_created.paginate :conditions => "user_id in (#{@user.id.to_s},#{@user.followings.up.collect{|f|f.other_user_id}.join(',')})", :page => params[:page], :per_page => 15
    end
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'activities/discussions_widget_small')) + "');" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def your_network_points
    @page_title = tr("Points in your network", "controller/feed", :sub_instance_name => current_sub_instance.name)
    if current_following_ids.empty?
      @activities = Activity.active.points_and_docs.paginate :conditions => "user_id = #{current_user.id.to_s}", :page => params[:page]
    else
      @activities = Activity.active.points_and_docs.paginate :conditions => "user_id in (#{current_user.id.to_s},#{current_following_ids.join(',')})", :page => params[:page]
    end
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def your_network_capital
    @page_title = tr("{currency_name} in your network", "controller/feed", :sub_instance_name => current_sub_instance.name, :currency_name => current_instance.currency_name.titleize)
    if current_following_ids.empty?
      @activities = Activity.active.capital.by_recently_created.paginate :conditions => "user_id = #{current_user.id.to_s}", :page => params[:page]
    else
      @activities = Activity.active.capital.by_recently_created.paginate :conditions => "user_id in (#{current_user.id.to_s},#{current_following_ids.join(',')})", :page => params[:page]
    end
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def your_network_changes
    @page_title = tr("M&A activity in your network", "controller/feed", :sub_instance_name => current_sub_instance.name)
    if current_following_ids.empty?
      @activities = Activity.active.changes.by_recently_created.paginate :conditions => "user_id = #{current_user.id.to_s}", :page => params[:page]
    else
      @activities = Activity.active.changes.by_recently_created.paginate :conditions => "user_id in (#{current_user.id.to_s},#{current_following_ids.join(',')})", :page => params[:page]
    end
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def your_idea_activities
    @page_title = tr("What's happening on {sub_instance_name}?", "controller/feed", :sub_instance_name => current_sub_instance.name)
    @activities = nil
    if current_idea_ids.any?
      @activities = Activity.active.last_seven_days.by_recently_created.paginate :conditions => ["idea_id in (?)",current_idea_ids], :page => params[:page]
    end
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def your_idea_official
    @page_title = tr("What {official_user_name} is doing on {sub_instance_name}", "controller/feed", :sub_instance_name => current_sub_instance.name, :official_user_name => current_instance.official_user.name)
    @activities = nil
    if current_idea_ids.any?
      @activities = Activity.active.by_recently_created.paginate :conditions => ["(type like 'ActivityIdeaOfficialStatus%' or user_id = #{current_instance.official_user_id}) and idea_id in (?)",current_idea_ids], :page => params[:page]
    end
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def your_idea_changes
    @page_title = tr("Acquisitions proposed on {sub_instance_name}", "controller/feed", :sub_instance_name => current_sub_instance.name)
    @changes = nil
    if current_idea_ids.any?
      @changes = Change.suggested.by_recently_created.paginate :conditions => ["idea_id in (?)",current_idea_ids], :page => params[:page]
    end
    respond_to do |format|
      format.html { render :action => "change_list" }
      format.xml { render :xml => @changes.to_xml(:include => [:idea, :new_idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @changes.to_json(:include => [:idea, :new_idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def your_idea_changes_voting
    @page_title = tr("Acquisitions to vote on", "controller/feed", :sub_instance_name => current_sub_instance.name)
    @changes = nil
    if current_idea_ids.any?
      @changes = Change.voting.by_recently_started.paginate :conditions => ["idea_id in (?)",current_idea_ids], :page => params[:page]
    end
    respond_to do |format|
      format.html { render :action => "change_list" }
      format.xml { render :xml => @changes.to_xml(:include => [:idea, :new_idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @changes.to_json(:include => [:idea, :new_idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def your_idea_changes_activity
    @page_title = tr("M&A activity on {sub_instance_name}", "controller/feed", :sub_instance_name => current_sub_instance.name)
    @activities = nil
    if current_idea_ids.any?
      @activities = Activity.active.changes.for_all_users.by_recently_created.paginate :conditions => ["idea_id in (?)",current_idea_ids], :page => params[:page]
    end
    respond_to do |format|
      format.html { render :action => "changes_activity" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def your_idea_discussions
    @page_title = tr("Discussions on {sub_instance_name}", "controller/feed", :sub_instance_name => current_sub_instance.name)
    @activities = nil
    if @user.endorsements_count > 0
      @activities = Activity.active.last_seven_days.discussions.for_all_users.by_recently_updated.paginate :conditions => ["idea_id in (?)",@user.endorsements.active_and_inactive.collect{|e|e.idea_id}], :page => params[:page], :per_page => 15
    end
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'activities/discussions_widget_small')) + "');" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def your_idea_points
    @page_title = tr("Points on {sub_instance_name}", "controller/feed", :sub_instance_name => current_sub_instance.name)
    @activities = nil
    if current_idea_ids.any?
      @activities = Activity.active.last_seven_days.points_and_docs.paginate :conditions => ["idea_id in (?)",current_idea_ids], :page => params[:page]
    end
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def your_ideas_created_activities
    @page_title = tr("Everything happening on ideas you created", "controller/feed", :sub_instance_name => current_sub_instance.name)
    @activities = nil
    created_idea_ids = current_user.created_ideas.collect{|p|p.id}
    if created_idea_ids.any?
      @activities = Activity.active.by_recently_created.paginate :conditions => ["idea_id in (?)",created_idea_ids], :page => params[:page]
    end
    @rss_url = url_for(:only_path => false, :controller => "rss", :action => "your_ideas_created_activities", :format => "rss", :c => current_user.rss_code)
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def your_ideas_created_official
    @page_title = tr("What {official_user_name} is doing on ideas you created", "controller/feed", :sub_instance_name => current_sub_instance.name, :official_user_name => current_instance.official_user.name)
    @activities = nil
    created_idea_ids = current_user.created_ideas.collect{|p|p.id}
    if created_idea_ids.any?
      @activities = Activity.active.by_recently_created.paginate :conditions => ["(type like 'ActivityIdeaOfficialStatus%' or user_id = #{current_instance.official_user_id}) and idea_id in (?)",created_idea_ids], :page => params[:page]
    end
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def your_ideas_created_changes
    @page_title = tr("M&A activity on ideas you created", "controller/feed", :sub_instance_name => current_sub_instance.name)
    @activities = nil
    created_idea_ids = current_user.created_ideas.collect{|p|p.id}
    if created_idea_ids.any?
      @activities = Activity.active.changes.for_all_users.by_recently_created.paginate :conditions => ["idea_id in (?)",created_idea_ids], :page => params[:page]
    end
    respond_to do |format|
      format.html { render :action => "changes_activity" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def your_ideas_created_discussions
    @page_title = tr("Discussions on ideas you created", "controller/feed", :sub_instance_name => current_sub_instance.name)
    @activities = nil
    created_idea_ids = @user.created_ideas.collect{|p|p.id}
    if created_idea_ids.any?
      @activities = Activity.active.discussions.for_all_users.by_recently_updated.paginate :conditions => ["idea_id in (?)",created_idea_ids], :page => params[:page], :per_page => 15
    end
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'activities/discussions_widget_small')) + "');" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def your_ideas_created_points
    @page_title = tr("Points activity on ideas you created", "controller/feed", :sub_instance_name => current_sub_instance.name)
    @activities = nil
    created_idea_ids = current_user.created_ideas.collect{|p|p.id}
    if created_idea_ids.any?
      @activities = Activity.active.points_and_docs.paginate :conditions => ["idea_id in (?)",created_idea_ids], :page => params[:page]
    end
    respond_to do |format|
      format.html { render :action => "activity_list" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  private

  def check_for_user
    if params[:user_id]
      @user = User.find(params[:user_id])
    elsif user_signed_in?
      @user = current_user
    else
      access_denied! and return
    end
  end

  def setup_menu_items
    @items = Hash.new
    @items[1]=[tr("Key activities", "view/feed/_nav"), url_for(:controller => "feed", :action => "top")]
    @items[2]=[tr("Everything", "view/feed/_nav"), url_for(:controller => "feed", :action => "activities")]
    #@items[2]=[tr("All discussions", "view/feed/_nav"), url_for(:controller => "feed", :action => "discussions")]
    #@items[4]=[tr("Points", "view/feed/_nav"), url_for(:controller => "feed", :action => "points")]
    if user_signed_in?
      @items[3]=[tr("Your discussions", "view/feed/_nav"), url_for(:controller => "feed", :action => "your_discussions")]
      @items[4]=[tr("Discussions on #{IDEA_TOKEN_PLURAL} you endorse", "view/feed/_nav"), url_for(:controller => "feed", :action => "your_idea_discussions")]
      @items[5]=[tr("Discussions on #{IDEA_TOKEN_PLURAL} you created", "view/feed/_nav"), url_for(:controller => "feed", :action => "your_ideas_created_discussions")]
      @items[6]=[tr("Your activities", "view/feed_nav"), url_for(controller: 'feed', action: 'your_activities')]
    end
    @items
  end

end
