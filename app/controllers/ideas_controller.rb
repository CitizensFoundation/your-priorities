require 'date'

class IdeasController < ApplicationController
  impressionist :actions=>[:show]

  before_filter :authenticate_user!, :only => [:yours_finished, :yours_ads, :yours_top, :yours_lowest, :consider, :flag_inappropriate, :comment, :edit, :update,
                                           :tag, :tag_save, :opposed, :endorsed, :destroy, :new]
  before_filter :authenticate_admin!, :only => [:bury, :successful, :compromised, :intheworks, :failed, :abusive, :not_abusive, :move]
  before_filter :authenticate_sub_admin!, :only => [:change_category]
  before_filter :load_endorsement, :only => [:show, :show_feed, :activities, :endorsers, :opposers, :opposer_points, :endorser_points, :neutral_points, :everyone_points,
                                             :opposed_top_points, :endorsed_top_points, :idea_detail, :top_points, :discussions, :everyone_points ]
#  before_filter :disable_sub_nav, :only => [:show, :show_feed, :activities, :endorsers, :opposers, :opposer_points, :endorser_points, :neutral_points, :everyone_points,
#                                              :opposed_top_points, :endorsed_top_points, :idea_detail, :top_points, :discussions, :everyone_points ]
  before_filter :check_for_user, :only => [:yours, :network, :yours_finished, :yours_created]

  before_filter :setup_filter_dropdown

  caches_action :revised, :index, :top, :top_24hr, :top_7days, :top_30days,
                :ads, :controversial, :rising, :newest, :finished, :show,
                :top_points, :discussions, :endorsers, :opposers, :activities,
                :if => proc {|c| c.do_action_cache?},
                :cache_path => proc {|c| c.action_cache_path},
                :expires_in => 30.seconds

  layout :get_layout

  def  disable_sub_nav
    @skip_sub_navigation = true
  end


  # GET /ideas                                               7
  def index
    redirect_to :action=>"top"
    return false

    if params[:term] and request.xhr?
      ideas = Idea.published.find(:all, :select => "ideas.name", :conditions => ["name LIKE ?", "%#{params[:term]}%"], :order => "endorsements_count desc")
      idea_links = []
      ideas.each do |idea|
        idea_links << view_context.link_to(idea.name, idea_path(idea))
      end
    end

    respond_to do |format|
      format.html
      format.js { 
        if not idea_links
          render :nothing => true
        else
          render :json => idea_links
        end
      }
    end
  end

  def move
    # This function can only be used when users are shared between sub instances
    if request.post? and ENV['YRPRI_ALL_DOMAIN']
      from_sub_instance = SubInstance.current
      to_sub_instance = SubInstance.find(params[:idea][:sub_instance])
      SubInstance.current = to_sub_instance
      to_category_id = Category.first.id
      SubInstance.current = from_sub_instance
      @idea.sub_instance_id = to_sub_instance.id
      @idea.category_id = to_category_id
      @idea.save(:validate=>false)
      Point.unscoped.where(:idea_id=>@idea.id).each do |point|
        point.sub_instance_id = to_sub_instance.id
        point.save(:validate=>false)
      end
      Endorsement.unscoped.where(:idea_id=>@idea.id).each do |item|
        item.sub_instance_id = to_sub_instance.id
        item.save(:validate=>false)
      end
      Activity.unscoped.where(:idea_id=>@idea.id).each do |item|
        item.sub_instance_id = to_sub_instance.id
        item.save(:validate=>false)
        Comment.unscoped.where(:activity_id=>item.id).each do |item|
          item.sub_instance_id = to_sub_instance.id
          item.save(:validate=>false)
        end
      end
      Ad.unscoped.where(:idea_id=>@idea.id).each do |item|
        item.sub_instance_id = to_sub_instance.id
        item.save(:validate=>false)
      end
      ViewedIdea.unscoped.where(:idea_id=>@idea.id).each do |item|
        item.sub_instance_id = to_sub_instance.id
        item.save(:validate=>false)
      end
      UserMailer.sub_instance_changed(@idea.user, @idea, from_sub_instance, to_sub_instance, params[:idea][:finished_status_message]).deliver
      redirect_to @idea.show_url
    end
  end

  # GET /ideas/yours
  def yours
    @page_title = tr("Your #{IDEA_TOKEN_PLURAL} at {sub_instance_name}", "controller/ideas", :sub_instance_name => current_sub_instance.name)
    @ideas = @user.endorsements.active.by_position.paginate :include => :idea, :page => params[:page], :per_page => params[:per_page]
    @rss_url = yours_ideas_url(:format => 'rss')
    get_endorsements
    respond_to do |format|
      format.html
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end
  
  # GET /ideas/yours_top
  def yours_top
    @page_title = tr("Your #{IDEA_TOKEN_PLURAL} ranked highest by {sub_instance_name} members", "controller/ideas", :sub_instance_name => current_sub_instance.name)
    @ideas = current_user.endorsements.active.by_idea_position.paginate :include => :idea, :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "yours" }
      format.xml { render :xml => @endorsements.to_xml(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @endorsements.to_json(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end  
  
  # GET /ideas/yours_lowest
  def yours_lowest
    @page_title = tr("Your #{IDEA_TOKEN_PLURAL} ranked lowest by {sub_instance_name} members", "controller/ideas", :sub_instance_name => current_sub_instance.name)
    @ideas = current_user.endorsements.active.by_idea_lowest_position.paginate :include => :idea, :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "yours" }
      format.xml { render :xml => @endorsements.to_xml(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @endorsements.to_json(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end  
  
  # GET /ideas/yours_created
  def yours_created
    @page_title = tr("#{IDEA_TOKEN_PLURAL_CAPS} you created at {sub_instance_name}", "controller/ideas", :sub_instance_name => current_sub_instance.name)
    @ideas = @user.created_ideas.published.top_rank.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end  

  # GET /ideas/network
  def network
    @page_title = tr("Your network's ideas", "controller/ideas", :sub_instance_name => current_sub_instance.name)
    @rss_url = network_ideas_url(:format => 'rss')
    if @user.followings_count > 0
      @ideas = Endorsement.active.find(:all,
        :select => "endorsements.idea_id, sum((#{Endorsement.max_position+1}-endorsements.position)*endorsements.value) as score, count(*) as endorsements_number, ideas.*",
        :joins => "endorsements INNER JOIN ideas ON ideas.id = endorsements.idea_id",
        :conditions => ["endorsements.user_id in (?) and endorsements.position <= #{Endorsement.max_position}",@user.followings.up.collect{|f|f.other_user_id}], 
        :group => "endorsements.idea_id",
        :order => "score desc").paginate :page => params[:page], :per_page => params[:per_page]
        @endorsements = @user.endorsements.active.find(:all, :conditions => ["idea_id in (?)", @ideas.collect {|c| c.idea_id}])
    end
    respond_to do |format|
      format.html
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end
  
  # GET /ideas/yours_finished
  def yours_finished
    @page_title = tr("Your #{IDEA_TOKEN_PLURAL} in progress at {sub_instance_name}", "controller/ideas", :sub_instance_name => current_sub_instance.name)
    @ideas = @user.endorsements.finished.find(:all, :order => "ideas.status_changed_at desc", :include => :idea).paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html { render :action => "yours" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
    if user_signed_in? and request.format == 'html' and current_user.unread_notifications_count > 0
      for n in current_user.received_notifications.all
        n.read! if n.class == NotificationIdeaFinished and n.unread?
      end    
    end
  end  

  # GET /ideas/ads
  def ads
    @page_title = tr("Ads running at {sub_instance_name}", "controller/ideas", :sub_instance_name => current_sub_instance.name)
    @ads = Ad.active_first.paginate :include => [:user, :idea], :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html
      format.xml { render :xml => @ads.to_xml(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ads.to_json(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /ideas/yours_ads
  def yours_ads
    @page_title = tr("Your ads", "controller/ideas", :sub_instance_name => current_sub_instance.name)
    @ads = current_user.ads.active_first.paginate :include => [:user, :idea], :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html
      format.xml { render :xml => @ads.to_xml(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ads.to_json(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end  

  # GET /ideas/consider
  def consider
    @page_title = tr("#{IDEA_TOKEN_PLURAL_CAPS} you should consider", "controller/ideas", :sub_instance_name => current_sub_instance.name)
    @ideas = current_user.recommend(25)
    if @ideas.empty?
      flash[:error] = tr("You need to endorse a few things before we can recommend other ideas for you to consider. Here are a few random ideas to get started.", "controller/ideas")
      redirect_to :action => "random"
      return
    end
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end    
  end

  # GET /ideas/top
  def by_impressions
    @position_in_idea_name = false
    @page_title = tr("Top read", "controller/ideas")
    @ideas = Idea.published.category_filter.by_impressions_count.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def most_discussed
    @position_in_idea_name = false
    @page_title = tr("Most discussed", "controller/ideas")
    @ideas = Idea.published.category_filter.by_most_discussed.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /ideas/top
  def top
    @position_in_idea_name = false
    @page_title = tr("Top #{IDEA_TOKEN_PLURAL}", "controller/ideas")
    @rss_url = top_ideas_url(:format => 'rss')
    @ideas = Idea.published.category_filter.top_rank.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /ideas/top_24hr
  def top_24hr
    @position_in_idea_name = false
    @page_title = tr("Top #{IDEA_TOKEN_PLURAL} past 24 hours", "controller/ideas")
    @rss_url = top_ideas_url(:format => 'rss')
    @ideas = Idea.published.category_filter.top_24hr.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /ideas/top_7days
  def top_7days
    @position_in_idea_name = false
    @page_title = tr("Trending #{IDEA_TOKEN_PLURAL}", "controller/ideas")
    @rss_url = top_ideas_url(:format => 'rss')
    @ideas = Idea.published.category_filter.top_7days.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /ideas/top_30days
  def top_30days
    @position_in_idea_name = false
    @page_title = tr("Top #{IDEA_TOKEN_PLURAL} past 30 days", "controller/ideas")
    @rss_url = top_ideas_url(:format => 'rss')
    @ideas = Idea.published.category_filter.top_30days.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /ideas/rising
  def rising
    @position_in_idea_name = false
    @page_title = tr("#{IDEA_TOKEN_PLURAL_CAPS} rising in the rankings", "controller/ideas")
    @rss_url = rising_ideas_url(:format => 'rss')
    @ideas = Idea.published.category_filter.rising.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  # GET /ideas/falling
  def falling
    @position_in_idea_name = false
    @page_title = tr("#{IDEA_TOKEN_PLURAL_CAPS} falling in the rankings", "controller/ideas")
    @rss_url = falling_ideas_url(:format => 'rss')
    @ideas = Idea.published.category_filter.falling.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end  
  
  # GET /ideas/controversial
  def controversial
    @position_in_idea_name = false
    @page_title = tr("Most controversial #{IDEA_TOKEN_PLURAL}", "controller/ideas")
    @rss_url = controversial_ideas_url(:format => 'rss')
    @ideas = Idea.published.category_filter.controversial.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  # GET /ideas/finished
  def finished
    @position_in_idea_name = false
    @page_title = tr("#{IDEA_TOKEN_PLURAL_CAPS} finished", "controller/ideas")
    @rss_url = finished_ideas_url(:format => 'rss')
    @ideas = Idea.finished.not_removed.top_rank.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end    
  end

  def finished_successful
    @position_in_idea_name = false
    @page_title = tr("#{IDEA_TOKEN_PLURAL_CAPS} finished successfully", "controller/ideas")
    @rss_url = finished_ideas_url(:format => 'rss')
    @ideas = Idea.successful.not_removed.top_rank.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def finished_failed
    @position_in_idea_name = false
    @page_title = tr("#{IDEA_TOKEN_PLURAL_CAPS} finished successfully", "controller/ideas")
    @rss_url = finished_ideas_url(:format => 'rss')
    @ideas = Idea.failed.not_removed.top_rank.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def finished_in_progress
    @position_in_idea_name = false
    @page_title = tr("#{IDEA_TOKEN_PLURAL_CAPS} finished successfully", "controller/ideas")
    @rss_url = finished_ideas_url(:format => 'rss')
    @ideas = Idea.in_progress.not_removed.top_rank.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def finished_compromised
    @position_in_idea_name = false
    @page_title = tr("#{IDEA_TOKEN_PLURAL_CAPS} finished successfully", "controller/ideas")
    @rss_url = finished_ideas_url(:format => 'rss')
    @ideas = Idea.compromised.not_removed.top_rank.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /ideas/random
  def random
    @page_title = tr("Random #{IDEA_TOKEN_PLURAL}", "controller/ideas")
    if User.adapter == 'postgresql'
      @ideas = Idea.published.paginate :order => "RANDOM()", :page => params[:page], :per_page => params[:per_page]
    else
      @ideas = Idea.published.paginate :order => "RANDOM()", :page => params[:page], :per_page => params[:per_page]
    end
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /ideas/newest
  def newest
    @position_in_idea_name = false
    @page_title = tr("Newest #{IDEA_TOKEN_PLURAL}", "controller/ideas")
    @rss_url = newest_ideas_url(:format => 'rss')
    @ideas = Idea.published.category_filter.newest.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end    
  end
  
  # GET /ideas/untagged
  def untagged
    @page_title = tr("Untagged (or uncategorized) ideas", "controller/ideas")
    @rss_url = untagged_ideas_url(:format => 'rss')
    @ideas = Idea.published.untagged.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end  
  end  
  
  def revised
    @page_title = tr("Recently revised ideas", "controller/ideas", :sub_instance_name => current_sub_instance.name)
    @ideas = Idea.published.revised.uniq.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html
      format.xml { render :xml => @revisions.to_xml(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @revisions.to_json(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end 

  # GET /ideas/1
  def show
    if @idea.sub_instance_id != SubInstance.current.id
      redirect_to @idea.show_url
    else
      @page_title = @idea.name
      @show_only_last_process = false
      setup_top_points(500)

      @activities = @idea.activities.active.top_discussions.for_all_users.paginate :page => params[:page]
      if user_signed_in? and @endorsement
        if @endorsement.is_up?
          @relationships = @idea.relationships.endorsers_endorsed.by_highest_percentage.find(:all, :include => :other_idea).group_by {|o|o.other_idea}
        elsif @endorsement.is_down?
          @relationships = @idea.relationships.opposers_endorsed.by_highest_percentage.find(:all, :include => :other_idea).group_by {|o|o.other_idea}
        end
      else
        @relationships = @idea.relationships.who_endorsed.by_highest_percentage.find(:all, :include => :other_idea).group_by {|o|o.other_idea}
      end
      @endorsements = nil
      if user_signed_in? # pull all their endorsements on the ideas shown
        current_user.have_seen_idea!(@idea)
        @endorsements = Endorsement.find(:all, :conditions => ["idea_id in (?) and user_id = ? and status='active'", @relationships.collect {|other_idea, relationship| other_idea.id},current_user.id])
      end
      respond_to do |format|
        format.html { render :action => "show" }
        format.xml { render :xml => @idea.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
        format.json { render :json => @idea.to_json(:except => NB_CONFIG['api_exclude_fields']) }
      end
    end
  end

  def show_feed
    last = params[:last].blank? ? Time.now + 1.second : Time.parse(params[:last])
    @activities = @idea.activities.active.top_discussions.feed(last).for_all_users :include => :user
    respond_to do |format|
      format.js
    end
  end

  def opposer_points
    @page_title = tr("Points opposing {idea_name}", "controller/ideas", :idea_name => @idea.name)
    @point_value = -1  
    @points = @idea.points.published.by_opposer_helpfulness.paginate :page => params[:page], :per_page => params[:per_page]
    get_qualities
    respond_to do |format|
      format.html { render :action => "points" }
      format.xml { render :xml => @points.to_xml(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @points.to_json(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  def endorser_points
    @page_title = tr("Points supporting {idea_name}", "controller/ideas", :idea_name => @idea.name)
    @point_value = 1
    @points = @idea.points.published.by_endorser_helpfulness.paginate :page => params[:page], :per_page => params[:per_page]
    get_qualities
    respond_to do |format|
      format.html { render :action => "points" }
      format.xml { render :xml => @points.to_xml(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @points.to_json(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  def neutral_points
    @page_title = tr("Points about {idea_name}", "controller/ideas", :idea_name => @idea.name)
    @point_value = 2 
    @points = @idea.points.published.by_neutral_helpfulness.paginate :page => params[:page], :per_page => params[:per_page]
    get_qualities
    respond_to do |format|
      format.html { render :action => "points" }
      format.xml { render :xml => @points.to_xml(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @points.to_json(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end  
  
  def everyone_points
    return redirect_to_idea
    @page_title = tr("Best points on {idea_name}", "controller/ideas", :idea_name => @idea.name)
    @point_value = 0 
    @points = @idea.points.published.by_helpfulness.paginate :page => params[:page], :per_page => params[:per_page]
    get_qualities
    respond_to do |format|
      format.html { render :action => "points" }
      format.xml { render :xml => @points.to_xml(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @points.to_json(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end  

  def opposed_top_points
    return redirect_to_idea
    @page_title = tr("Points opposing {idea_name}", "controller/ideas", :idea_name => @idea.name)
    @point_value = -1
    if params[:by_newest]
      @points = @idea.points.published.down_value.by_recently_created.paginate :page => params[:page], :per_page => params[:per_page]
    else
      @points = @idea.points.published.down_value.by_helpfulness.paginate :page => params[:page], :per_page => params[:per_page]
    end
    get_qualities
    respond_to do |format|
      format.html { render :action => "points" }
      format.xml { render :xml => @points.to_xml(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @points.to_json(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  def endorsed_top_points
    return redirect_to_idea
    @page_title = tr("Points supporting {idea_name}", "controller/ideas", :idea_name => @idea.name)
    @point_value = 1
    if params[:by_newest]
      @points = @idea.points.published.up_value.by_recently_created.paginate :page => params[:page], :per_page => params[:per_page]
    else
      @points = @idea.points.published.up_value.by_helpfulness.paginate :page => params[:page], :per_page => params[:per_page]
    end
    get_qualities
    respond_to do |format|
      format.html { render :action => "points" }
      format.xml { render :xml => @points.to_xml(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @points.to_json(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def idea_detail
    setup_top_points(2)
    render :partial=>"ideas/idea_detail", :layout=>false
  end

  def top_points
    return redirect_to_idea

    @page_title = tr("Top points", "controller/ideas", :idea_name => @idea.name)
    @activities = @idea.activities.active.top_discussions.for_all_users :include => :user
    setup_top_points(50000)
    respond_to do |format|
      format.html { render :action => "top_points" }
      format.xml { render :xml => @points.to_xml(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @points.to_json(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end  
  
  def points
    redirect_to :action => "everyone_points"
  end
  
  def discussions
    @page_title = tr("Discussions on {idea_name}", "controller/ideas", :idea_name => @idea.name)
    @activities = @idea.activities.active.discussions.by_recently_updated.for_all_users.paginate :page => params[:page], :per_page => 10
    #if @activities.empty? # pull all activities if there are no discussions
    #  @activities = @idea.activities.active.paginate :page => params[:page]
    #end
    respond_to do |format|
      format.html { render :action => "activities" }
      format.xml { render :xml => @activities.to_xml(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
    end
  end  
  
  def comments
    @idea = Idea.find(params[:id])
    @page_title = tr("Latest comments on {idea_name}", "controller/ideas", :idea_name => @idea.name)
    @comments = Comment.published.by_recently_created.find(:all, :conditions => ["activities.idea_id = ?",@idea.id], :include => :activity).paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html
      format.rss { render :template => "rss/comments" }
      format.xml { render :xml => @comments.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @comments.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end    
  end
  
  # GET /ideas/1/activities
  def activities
    @page_title = tr("Activity on {idea_name}", "controller/ideas", :idea_name => @idea.name)
    @activities = @idea.activities.active.for_all_users.by_recently_created.paginate :include => :user, :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html
      format.rss { render :template => "rss/activities" }
      format.xml { render :xml => @activities.to_xml(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
    end
  end 
  
  # GET /ideas/1/endorsers
  def endorsers
    return redirect_to_idea
    @page_title = tr("{number} people endorse {idea_name}", "controller/ideas", :idea_name => @idea.name, :number => @idea.up_endorsements_count)
    if request.format != 'html'
      @endorsements = @idea.endorsements.active_and_inactive.endorsing.paginate :page => params[:page], :per_page => params[:per_page], :include => :user
    end
    respond_to do |format|
      format.html
      format.xml { render :xml => @endorsements.to_xml(:include => :user, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @endorsements.to_json(:include => :user, :except => NB_CONFIG['api_exclude_fields']) }      
    end
  end

  # GET /ideas/1/opposers
  def opposers
    return redirect_to_idea
    @page_title = tr("{number} people opposed {idea_name}", "controller/ideas", :idea_name => @idea.name, :number => @idea.down_endorsements_count)
    if request.format != 'html'
      @endorsements = @idea.endorsements.active_and_inactive.opposing.paginate :page => params[:page], :per_page => params[:per_page], :include => :user
    end
    respond_to do |format|
      format.html
      format.xml { render :xml => @endorsements.to_xml(:include => :user, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @endorsements.to_json(:include => :user, :except => NB_CONFIG['api_exclude_fields']) }      
    end
  end

  # GET /ideas/new
  # GET /ideas/new.xml
  def new
    @page_title = tr("New #{IDEA_TOKEN} at {sub_instance_name}", "controller/ideas", :sub_instance_name => current_sub_instance.name)
    @idea = Idea.new unless @idea
    @idea.points.build

    if @ideas
      @endorsements = Endorsement.find(:all, :conditions => ["idea_id in (?) and user_id = ? and status='active'", @ideas.collect {|c| c.id},current_user.id])
    end    

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /ideas/1/edit
  def edit
    @idea = Idea.find(params[:id])
    @page_name = tr("Edit {idea_name}", "controller/ideas", :idea_name => @idea.name)
    if not (current_user.id == @idea.user_id and @idea.endorsements_count < 2) and not current_user.is_admin?
      flash[:error] = tr("You cannot change a idea's name once other people have endorsed it.", "controller/ideas")
      redirect_to @idea and return
    end
    respond_to do |format|
      format.html # new.html.erb
    end    
  end
  
  # POST /ideas
  # POST /ideas.xml
  def create
    if not user_signed_in?
      flash[:notice] = tr("First you need to fill out this quick form and agree to the rules, then you can start adding your ideas.", "controller/ideas")
      session[:query] = params[:idea][:name] if params[:idea]
      access_denied!
      return
    end

    if @block_new_ideas
      flash[:notice] = tr("This website is closed for submission of new ideas.", "controller/ideas")
      session[:query] = params[:idea][:name] if params[:idea]
      access_denied!
      return
    end

    Rails.logger.debug("Point character length: #{params[:idea][:points_attributes]["0"][:content].length} #{params[:idea][:name].length}")

    if current_sub_instance and current_sub_instance.required_tags and not params[:idea][:idea_type]
      # default to the first tag
      params[:idea][:idea_type] = current_sub_instance.required_tags.split(',')[0]
    end

    @idea = Idea.new(params[:idea])
    tags = []
    tags << @idea.category.name if @idea.category
    params.each do |p,v|
      tags << v if p.include?("special_checkbox_tag_")
    end
    params.each do |a,b|
      tags << b if a.include?("sub_tag_")
    end
    tags += params[:custom_tags].split(",").collect {|t| t.strip} if params[:custom_tags] and params[:custom_tags]!=""

    unless tags.empty?
      @idea.issue_list = tags.join(",")
    end
    @idea.user = current_user
    @idea.ip_address = request.remote_ip
    @idea.request = request
    @saved = @idea.save
    
    if @saved
      first_point = @idea.points.first
      first_point.user = current_user
      first_point.setup_revision
      first_point.reload
      @endorsement = @idea.endorse(current_user,request,@referral)
      IdeaRevision.create_from_idea(@idea,request.remote_ip,request.env['HTTP_USER_AGENT'])
      #quality = first_point.point_qualities.find_or_create_by_user_id_and_value(current_user.id, true)
#      if current_user.endorsements_count > 24
#        session[:endorsement_page] = (@endorsement.position/25).to_i+1
#        session[:endorsement_page] -= 1 if @endorsement.position == (session[:endorsement_page]*25)-25
#      end
    else
      # see if it already exists
      query = params[:idea][:name].strip
      same_name_idea = Idea.find(:first, :conditions => ["name = ? and status = 'published'", query], :order => "endorsements_count desc")
      flash[:current_same_name_idea_id] = same_name_idea.id if same_name_idea
    end
    
    respond_to do |format|
      if @saved
        session[:show_tagging]=true
        format.html {
          flash[:notice] = tr("Thanks for adding {idea_name}", "controller/ideas", :idea_name => @idea.name)
          redirect_to @idea
        }
        format.js {
          render :update do |page|
            page.redirect_to @idea
          end
        }        
      else
        format.html { render :controller => "ideas", :action => "new", :notice=>flash[:notice] }
      end
    end
  end

  # POST /ideas/1/endorse
  def endorse
    @value = (params[:value]||1).to_i
    @idea = Idea.unscoped.find(params[:id])
    if not user_signed_in?
      session[:idea_id] = @idea.id
      session[:value] = @value
      respond_to do |format|
        format.js {
          render :update do |page|
            page.redirect_to new_user_session_path
          end
          return
        }
      end
      access_denied!
      return
    end
    if @value == 1
      @endorsement = @idea.endorse(current_user,request,@referral)
    else
      @endorsement = @idea.oppose(current_user,request,@referral)
    end
    if params[:ad_id]    
      @ad = Ad.find(params[:ad_id])
      @ad.vote(current_user,@value,request) if @ad
    else
      @ad = Ad.unscoped.find_by_idea_id_and_status(@idea.id,'active')
      if @ad and @ad.shown_ads.find_by_user_id(current_user.id)
        @ad.vote(current_user,@value,request) 
      end
    end
    if current_user.endorsements_count > 24
      session[:endorsement_page] = (@endorsement.position/25).to_i+1
      session[:endorsement_page] -= 1 if @endorsement.position == (session[:endorsement_page]*25)-25
    end
    @idea.reload
    respond_to do |format|
      format.js {
        render :update do |page|
          if params[:region] == 'idea_left'
            page.replace_html 'idea_' + @idea.id.to_s + "_button",render(:partial => "ideas/debate_buttons", :locals => {:force_debate_to_new=>(params[:force_debate_to_new] and params[:force_debate_to_new].to_i==1) ? true : false, :idea => @idea, :endorsement => @endorsement, :region=>"idea_left"})
            page.replace_html 'idea_' + @idea.id.to_s + "_position",render(:partial => "endorsements/position", :locals => {:endorsement => @endorsement})
            page.replace 'endorser_link', render(:partial => "ideas/endorser_link")
            page.replace 'opposer_link', render(:partial => "ideas/opposer_link")
            if @value == 1          
              @activity = ActivityEndorsementNew.unscoped.find_by_idea_id_and_user_id(@idea.id,current_user.id, :order => "created_at desc")
            else
              @activity = ActivityOppositionNew.unscoped.find_by_idea_id_and_user_id(@idea.id,current_user.id, :order => "created_at desc")
            end            
            if @activity and not params[:no_activites]
              page.insert_html :top, 'activities', render(:partial => "activities/show", :locals => {:activity => @activity, :suffix => "_noself"})
            end
          elsif params[:region] == 'idea_subs'
            page.replace_html 'idea_' + @idea.id.to_s + "_button",render(:partial => "ideas/button_subs", :locals => {:idea => @idea, :endorsement => @endorsement})
            page.replace 'endorser_link', render(:partial => "ideas/endorser_link")
            page.replace 'opposer_link', render(:partial => "ideas/opposer_link")
          elsif params[:region] == 'idea_inline'
            page<<"$('.idea_#{@idea.id.to_s}_button_small').replaceWith('#{js_help.escape_javascript(render(:partial => "ideas/debate_buttons", :locals => {:force_debate_to_new=>(params[:force_debate_to_new] and params[:force_debate_to_new].to_i==1) ? true : false, :idea => @idea, :endorsement => @endorsement, :region => params[:region]}))}')"
            page<<"$('.idea_#{@idea.id.to_s}_endorsement_count').replaceWith('#{js_help.escape_javascript(render(:partial => "ideas/endorsement_count", :locals => {:idea => @idea}))}')"
          elsif params[:region] == 'encouragement_top' and @ad
            page.replace 'encouragements', render(:partial => "ads/pick")
            #page << 'if (jQuery("#notification_show").length > 0) { jQuery("#notification_show").corners(); }'
          else
            page << "alert('error');"
          end
          page.replace_html 'your_ideas_container', :partial => "ideas/yours"
        end
      }
    end
  end

  # PUT /ideas/1
  # PUT /ideas/1.xml
  def update
    @idea = Idea.find(params[:id])
    @previous_name = @idea.name
    @page_name = tr("Edit {idea_name}", "controller/ideas", :idea_name => @idea.name)

    if params[:idea]
      if params[:idea][:idea_type] and current_sub_instance and current_sub_instance.required_tags
        required_tags = current_sub_instance.required_tags.split(',')
        issues = @idea.issue_list
        if not issues.include?(params[:idea][:idea_type])
          new_issues = issues - required_tags
          new_issues << params[:idea][:idea_type]
          @idea.issue_list = new_issues.join(',')
        end
      end
      if params[:idea]["finished_status_date(1i)"]
        # TODO: isn't there an easier way to do this?
        params[:idea][:finished_status_date] = Date.new(params[:idea].delete("finished_status_date(1i)").to_i, params[:idea].delete("finished_status_date(2i)").to_i, params[:idea].delete("finished_status_date(3i)").to_i)
      end
      if params[:idea][:category]
        old_category = @idea.category
        new_category = Category.find(params[:idea][:category])
        params[:idea][:category] = new_category
        current_issues = @idea.issue_list
        remove_issues = [old_category.name]
        add_issues = [new_category.name]
        new_issues = add_issues | (current_issues - remove_issues)
        params[:idea][:issue_list] = new_issues.join(',')
      end
      if params[:idea][:finished_status_message]
        change_log = @idea_status_changelog = IdeaStatusChangeLog.new(
            idea_id: @idea.id,
            date: params[:idea][:finished_status_date],
            content: params[:idea][:finished_status_message],
            subject: params[:idea][:finished_status_subject]
        )
        @idea_status_changelog.save
      end
      if params[:idea][:official_status] and params[:idea][:official_status].to_i != @idea.official_status
        @change_status = params[:idea][:official_status].to_i
        #params[:idea].delete(:official_status)
      end
    end
    respond_to do |format|
      params[:idea][:group] = nil if params[:idea][:group]==""
      @idea.attributes = params[:idea]
      saved_with_attributes = @idea.save(:validate=>false)
      if params[:idea][:name] and saved_with_attributes and @previous_name != params[:idea][:name]
        # already renamed?
        @activity = ActivityIdeaRenamed.find_by_user_id_and_idea_id(current_user.id,@idea.id)
        if @activity
          @activity.update_attribute(:changed_at,Time.now)
        else
          @activity = ActivityIdeaRenamed.create(:user => current_user, :idea => @idea)
        end
        format.html {
          flash[:notice] = tr("Saved {idea_name}", "controller/ideas", :idea_name => @idea.name)
          redirect_to(@idea)
        }
        format.js {
          render :update do |page|
            page.select('#idea_' + @idea.id.to_s + '_edit_form').each {|item| item.remove}
            page.select('#activity_and_comments_' + @activity.id.to_s).each {|item| item.remove}
            page.insert_html :top, 'activities', render(:partial => "activities/show", :locals => {:activity => @activity, :suffix => "_noself"})
            page.replace_html 'idea_' + @idea.id.to_s + '_name', render(:partial => "ideas/name", :locals => {:idea => @idea})
            # page.visual_effect :highlight, 'idea_' + @idea.id.to_s + '_name'
          end
        }
      else
        format.html {
          if params[:idea][:finished_status_message]
            flash[:notice] = tr("Status updated with {status_text}", "controller/ideas", status_text: params[:idea][:finished_status_subject])
          end
          redirect_to(@idea)
        }
        format.js {
          render :update do |page|
            page.select('#idea_' + @idea.id.to_s + '_edit_form').each {|item| item.remove}
            page.insert_html :top, 'activities', render(:partial => "ideas/new_inline", :locals => {:idea => @idea})
            page['idea_name'].focus
          end
        }
      end
      @idea.reload

      if @change_status
        @idea.change_status!(@change_status)
        #@idea.delay.deactivate_endorsements
        #DeactivateEndorsements.perform_async(@idea.id)
      end
      if change_log
        @idea.create_status_update(change_log)
      end
    end
  end

  # PUT /ideas/1/create_short_url
  def create_short_url
    @idea = Idea.find(params[:id])
    @short_url = @idea.create_short_url
    if @short_url
      @idea.save(:validate => false)
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace "idea_short_url", render(:partial => "ideas/short_url", :locals => {:idea => @idea})
          page << "short_url.select();"
        end
      }
    end
  end

  # PUT /ideas/1/flag_inappropriate
  def flag
    @idea = Idea.find(params[:id])
    @idea.flag_by_user(current_user)

    respond_to do |format|
      format.html { redirect_to :back }
      format.js {
        render :update do |page|
          if false and current_user.is_admin?
            page.replace_html "idea_report_#{@idea.id}", render(:partial => "ideas/report_content", :locals => {:idea => @idea})
          else
            page.replace_html "idea_report_#{@idea.id}","<div class='warning_inline'> #{tr("Thanks for bringing this to our attention", "controller/ideas")}</div>"
          end
        end        
      }
    end    
  end  

  def abusive
    @idea = Idea.find(params[:id])
    @idea.do_abusive!(params[:warning_reason])
    @idea.remove!
    ActivityContentRemoval.create(idea: @idea, user: @idea.user, custom_text: params[:warning_reason])

    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html "idea_flag_#{@idea.id}", "<div class='warning_inline'>#{tr("The content has been deleted and a warning has been sent to the violating user", "controller/ideas")}</div>"
        end        
      }
    end    
  end

  def not_abusive
    @idea = Idea.find(params[:id])
    @idea.update_attribute(:flags_count, 0)
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html "idea_flag_#{@idea.id}",""
        end        
      }
    end    
  end
  
  # PUT /ideas/1/bury
  def bury
    @idea = Idea.find(params[:id])
    @idea.bury!
    ActivityIdeaBury.create(:idea => @idea, :user => current_user, :sub_instance => current_sub_instance)
    respond_to do |format|
      flash[:notice] = tr("{idea_name} is now buried, it will no longer be displayed in the charts.", "controller/ideas", :idea_name => @idea.name)
      format.html { redirect_to(@idea) }
    end
  end  
  
  # PUT /ideas/1/successful
  def successful
    @idea = Idea.find(params[:id])
    @idea.successful!
    respond_to do |format|
      flash[:notice] = tr("{idea_name} is now marked finished and successful", "controller/ideas", :idea_name => @idea.name)
      format.html { redirect_to(@idea) }
    end
  end  
  
  # PUT /ideas/1/intheworks
  def intheworks
    @idea = Idea.find(params[:id])
    @idea.intheworks!
    respond_to do |format|
      flash[:notice] = tr("{idea_name} is now marked 'in the works'", "controller/ideas", :idea_name => @idea.name)
      format.html { redirect_to(@idea) }
    end
  end  
  
  # PUT /ideas/1/failed
  def failed
    @idea = Idea.find(params[:id])
    @idea.failed!
    respond_to do |format|
      flash[:notice] = tr("{idea_name} is now marked finished and failed", "controller/ideas", :idea_name => @idea.name)
      format.html { redirect_to(@idea) }
    end
  end  
  
  # PUT /ideas/1/compromised
  def compromised
    @idea = Idea.find(params[:id])
    @idea.compromised!
    respond_to do |format|
      flash[:notice] = tr("{idea_name} is now marked finished but compromised", "controller/ideas", :idea_name => @idea.name)
      format.html { redirect_to(@idea) }
    end
  end  
  
  def endorsed
    @idea = Idea.find(params[:id])
    @endorsement = @idea.endorse(current_user,request,@referral)
    redirect_to @idea
  end

  def opposed
    @idea = Idea.find(params[:id])
    @endorsement = @idea.oppose(current_user,request,@referral)
    redirect_to @idea
  end

  # GET /ideas/1/tag
  def tag
    @idea = Idea.find(params[:id])
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html 'idea_' + @idea.id.to_s + '_tags', render(:partial => "ideas/tag", :locals => {:idea => @idea})
          page['idea_' + @idea.id.to_s + "_issue_list"].focus
        end        
      }
    end
  end

  # POST /ideas/1/tag
  def tag_save
    @idea = Idea.find(params[:id])
    @idea.update_attributes(params[:idea])
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html 'idea_' + @idea.id.to_s + '_tags', render(:partial => "ideas/tag_show", :locals => {:idea => @idea})
        end        
      }
    end
  end
  
  # DELETE /ideas/1
  def destroy
    if current_user.is_admin?
      @idea = Idea.find(params[:id])
    else
      @idea = current_user.created_ideas.find(params[:id])
    end
    return unless @idea
    name = @idea.name
    @idea.remove!
    flash[:notice] = tr("Permanently deleting {idea_name}. This may take a few minutes depending on how many endorsements/oppositions need to be removed.", "controller/ideas", :idea_name => name)
    respond_to do |format|
      format.html { redirect_to yours_created_ideas_url }
    end
  end

  def update_status
    @idea = Idea.find(params[:id])
    @page_name = tr("Edit the status of {idea_name}", "controller/ideas", :idea_name => @idea.name)
    if not current_user.is_admin?
      flash[:error] = tr("You cannot change a idea's name once other people have endorsed it.", "controller/ideas")
      redirect_to @idea and return
    end
    respond_to do |format|
      format.html
    end
  end

  def statistics
    @idea = Idea.find(params[:id])
    respond_to do |format|
      format.html
      format.js { render_to_facebox }
    end
  end

  def change_category
    @idea = Idea.find(params[:id])
    @page_name = tr("Change category for {idea_name}", "controller/ideas", :idea_name => @idea.name)

    if params[:idea]
      if params[:idea][:category]
        old_category = @idea.category
        new_category = Category.find(params[:idea][:category])
      end
    end
    if request.put?
      respond_to do |format|
        if params[:idea] and old_category and new_category and old_category != new_category
          @idea.category_id = new_category.id
          saved = @idea.save(:validate=>false)
          if saved
            UserMailer.category_changed(@idea.user, @idea, old_category, new_category).deliver
          end
        end
        format.html {
          if saved
            flash[:notice] = tr("Category changed", "controller/ideas")
          end
          redirect_to(@idea)
        }
        @idea.reload
      end
    end
  end

  private
  
    def get_endorsements
      @endorsements = nil
      if user_signed_in? # pull all their endorsements on the ideas shown
        @endorsements = current_user.endorsements.active.find(:all, :conditions => ["idea_id in (?)", @ideas.collect {|c| c.id}])
      end
    end
    
    def load_endorsement
      load_idea
      if @idea.status == 'removed' or @idea.status == 'abusive'
        flash[:notice] = tr("That #{IDEA_TOKEN} was deleted", "controller/ideas")
        redirect_to "/"
        return false
      end

      @endorsement = nil
      if user_signed_in? # pull all their endorsements on the ideas shown
        @endorsement = @idea.endorsements.active.find_by_user_id(current_user.id)
      end
    end    

    def redirect_to_idea
      redirect_to @idea.show_url, :status => :moved_permanently
    end

    def get_qualities(multi_points=nil)
      if multi_points
        @points=[]
        multi_points.each do |points|
          @points+=points
        end
      end
      if not @points.empty?
        @qualities = nil
        if user_signed_in? # pull all their qualities on the ideas shown
          @qualities = PointQuality.find(:all, :conditions => ["point_id in (?) and user_id = ? ", @points.collect {|c| c.id},current_user.id])
        end      
      end      
    end

    def setup_top_points(limit)
      @point_value = 0
      @points_new_up = Point.unscoped.where(idea_id: @idea.id).published.by_recently_created.up_value.limit(1)
      @points_new_up = [] unless @points_new_up.first and @points_new_up.first.created_at>DateTime.now-HOW_LONG_SHALL_NEW_POINTS_LIVE_IN_TOP_POINTS
      @points_new_down = Point.unscoped.where(idea_id: @idea.id).published.by_recently_created.down_value.limit(1)
      @points_new_down = [] unless @points_new_down.first and @points_new_down.first.created_at>DateTime.now-HOW_LONG_SHALL_NEW_POINTS_LIVE_IN_TOP_POINTS
      @points_top_up = Point.unscoped.where(idea_id: @idea.id).published.by_helpfulness.up_value.limit(limit).reject {|p| @points_new_up.include?(p)}
      @points_top_down = Point.unscoped.where(idea_id: @idea.id).published.by_helpfulness.down_value.limit(limit).reject {|p| @points_new_down.include?(p)}
      @total_up_points = Point.unscoped.where(idea_id: @idea.id).published.up_value.count
      @total_down_points = Point.unscoped.where(idea_id: @idea.id).published.down_value.count
      @total_up_points_new = [0,@total_up_points-@points_top_up.length].max
      @total_down_points_new = [0,@total_down_points-@points_top_down.length].max
      get_qualities([@points_new_up,@points_new_down,@points_top_up,@points_top_down])
    end

    def check_for_user
      if params[:user_id]
        @user = User.find(params[:user_id])
      elsif user_signed_in?
        @user = current_user
      else
        access_denied! and return
      end
    end

    def load_idea
      if not @idea and params[:id]
        begin
          @idea = Idea.find(params[:id])
        rescue
          @idea = Idea.unscoped.find(params[:id])
          if @idea
            redirect_to @idea.show_url, :status => :moved_permanently
          end
        end
      end
    end

    def setup_menu_items
      @items = Hash.new
      item_count = 0

      load_idea

      if [:show, :show_feed, :move, :update_status, :activities, :endorsers, :opposers, :opposer_points, :endorser_points, :neutral_points, :everyone_points,
          :opposed_top_points, :endorsed_top_points, :idea_detail, :top_points, :discussions, :everyone_point].include?(action_name.to_sym)
        setup_main_ideas_menu
      else
        @items[item_count+=1]=[tr("Last added ({count})", "view/ideas", :count=>Idea.not_removed.count), newest_ideas_url]
        @items[item_count+=1]=[tr("Top voted", "view/ideas"), top_ideas_url] unless @block_endorsements
        @items[item_count+=1]=[tr("Trending", "controller/ideas"), top_7days_ideas_url] unless @block_endorsements
        @items[item_count+=1]=[tr("Top read", "view/ideas"), by_impressions_ideas_url]
        @items[item_count+=1]=[tr("Most discussed", "view/ideas"), most_discussed_ideas_url]
        @items[item_count+=1]=[tr("Controversial", "view/ideas"), controversial_ideas_url]
        @items[item_count+=1]=[tr("Random", "view/ideas"), random_ideas_url]
        if false and user_signed_in? and current_user.ideas.count>0
          @items[item_count+=1]=[tr("Yours", "view/ideas"), yours_ideas_url]
        end
        @items[item_count+=1]=[tr("All officially finished ({count})", "view/ideas", :count=>Idea.finished.not_removed.count), finished_ideas_url] if Idea.finished.not_removed.count>0
        @items[item_count+=1]=[tr("Officially successful ({count})", "view/ideas", :count=>Idea.successful.not_removed.count), finished_successful_ideas_url] if Idea.successful.not_removed.count>0
        @items[item_count+=1]=[tr("Officially failed ({count})", "view/ideas",:count=>Idea.failed.not_removed.count), finished_failed_ideas_url] if Idea.failed.not_removed.count>0
        @items[item_count+=1]=[tr("Officially in progress ({count})", "view/ideas", :count=>Idea.in_progress.not_removed.count), finished_in_progress_ideas_url] if Idea.in_progress.not_removed.count>0
      end
      @items
    end
end


