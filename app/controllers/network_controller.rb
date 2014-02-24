class NetworkController < ApplicationController
  
  before_filter :authenticate_user!, :only => [:find, :following]
  before_filter :authenticate_admin!, :only => [:unverified, :deleted, :suspended, :probation, :warnings]
  before_filter :setup, :except => [:sub_instance]

  caches_action :index, :talkative, :ambassadors, :newest,
                :if => proc {|c| c.do_action_cache? },
                :cache_path => proc {|c| c.action_cache_path},
                :expires_in => 30.seconds

  before_filter :setup_filter_dropdown

  def index
    redirect_to :action=>"newest"
  end

  def influential
    @page_title = tr("Meet the most influential people at {sub_instance_name}", "controller/network", :sub_instance_name => current_sub_instance.name)
    if current_instance.users_count < 100
      @users = User.active.at_least_one_endorsement.by_capital.paginate :page => params[:page], :per_page => params[:per_page]
    else
      @users = User.active.at_least_one_endorsement.by_ranking.paginate :page => params[:page], :per_page => params[:per_page]
    end
    respond_to do |format|
      format.html
      format.xml { render :xml => @users.to_xml(:include => [:top_endorsement, :referral, :sub_instance_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:top_endorsement, :referral, :sub_instance_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end

  def talkative
    @page_title = tr("Most talkative at {sub_instance_name}", "controller/network", :sub_instance_name => current_sub_instance.name)
    @users = User.active.by_talkative.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html
      format.xml { render :xml => @users.to_xml(:include => [:top_endorsement, :referral, :sub_instance_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:top_endorsement, :referral, :sub_instance_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end  
  
  def ambassadors
    @page_title = tr("Ambassadors at {sub_instance_name}", "controller/network", :sub_instance_name => current_sub_instance.name)
    @users = User.active.by_invites_accepted.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html
      format.xml { render :xml => @users.to_xml(:include => [:top_endorsement, :referral, :sub_instance_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:top_endorsement, :referral, :sub_instance_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end  
  
  def twitterers
    @page_title = tr("Twitterers at {sub_instance_name}", "controller/network", :sub_instance_name => current_sub_instance.name)
    @users = User.active.at_least_one_endorsement.twitterers.by_twitter_count.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html
      format.xml { render :xml => @users.to_xml(:include => [:top_endorsement, :referral, :sub_instance_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:top_endorsement, :referral, :sub_instance_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end  

  def unverified
    @page_title = tr("Unverified subscription_accounts", "controller/network", :sub_instance_name => current_sub_instance.name)
    @users = User.pending.by_recently_created.paginate :page => params[:page], :per_page => 100
    respond_to do |format|
      format.html { render :action => "list" }
      format.xml { render :xml => @users.to_xml(:include => [:referral, :sub_instance_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:referral, :sub_instance_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end
  
  def warnings
    @page_title = tr("Warnings", "controller/network", :sub_instance_name => current_sub_instance.name)
    @users = User.warnings.by_recently_signed_in.paginate :page => params[:page], :per_page => 100
    respond_to do |format|
      format.html
      format.xml { render :xml => @users.to_xml(:include => [:referral, :sub_instance_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:referral, :sub_instance_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end

  def suspended
    @page_title = tr("Suspended subscription_accounts", "controller/network", :sub_instance_name => current_sub_instance.name)
    @users = User.suspended.by_suspended_at.paginate :page => params[:page], :per_page => 100
    respond_to do |format|
      format.html { render :action => "list" }
      format.xml { render :xml => @users.to_xml(:include => [:referral, :sub_instance_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:referral, :sub_instance_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end
  
  def probation
    @page_title = tr("Accounts on probation", "controller/network", :sub_instance_name => current_sub_instance.name)
    @users = User.probation.by_probation_at.paginate :page => params[:page], :per_page => 100
    respond_to do |format|
      format.html { render :action => "list" }
      format.xml { render :xml => @users.to_xml(:include => [:referral, :sub_instance_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:referral, :sub_instance_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end  
  
  def deleted
    @page_title = tr("Deleted subscription_accounts", "controller/network", :sub_instance_name => current_sub_instance.name)
    @users = User.removed.by_removed_at.paginate :page => params[:page], :per_page => 100
    respond_to do |format|
      format.html { render :action => "list" }
      format.xml { render :xml => @users.to_xml(:include => [:referral, :sub_instance_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:referral, :sub_instance_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end  

  def newest
    @page_title = tr("New members at {sub_instance_name}", "controller/network", :sub_instance_name => current_sub_instance.name)
    @users = User.active.at_least_one_endorsement.by_recently_created.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html
      format.xml { render :xml => @users.to_xml(:include => [:top_endorsement, :referral, :sub_instance_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:top_endorsement, :referral, :sub_instance_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end

  def find
    redirect_to user_contacts_path(current_user)
    return
  end

  def search
    @user = User.find_by_login(params[:user][:login])
    if @user
      redirect_to @user 
    else
      flash[:error] = tr("Could not find that member", "controller/network")
      redirect_to :controller => "network"
    end
  end
  
  def sub_instances
    if User.adapter == 'postgresql'
      @sub_instances = SubInstance.find(:all, :conditions => "logo_file_name is not null", :order => "RANDOM()")
    else
      @sub_instances = SubInstance.find(:all, :conditions => "logo_file_name is not null", :order => "RANDOM()")
    end
    @page_title = tr("Meet our sub_instances", "controller/network", :sub_instance_name => current_sub_instance.name)
    respond_to do |format|
      format.html
      format.xml { render :xml => @sub_instances.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @sub_instances.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end  

  def following
    @page_title = tr("People you're following at {sub_instance_name}", "controller/contacts", :sub_instance_name => current_sub_instance.name)
    unless current_following_ids.empty?
      @users = User.active.by_capital.find(:all, :conditions => ["id in (?)",current_following_ids]) #:page => params[:page], :per_page => params[:per_page]
    end
    respond_to do |format|
      format.html { render template: 'user_contacts/following' }
    end
  end

  private
  def setup
    @user = User.new
    @row = (params[:page].to_i-1)*25
    @row = 0 if params[:page].to_i <= 1
  end 

  def setup_menu_items
     @items = Hash.new
     #@items[1]=[tr("Influential", "view/network/_nav"), url_for(:controller => "network", :action => "influential")]
     #@items[2]=[tr("Talkative", "view/network/_nav"), url_for(:controller => "network", :action => "talkative")]
     @items[1]=[tr("New members", "view/network/_nav"), url_for(:controller => "network", :action => "newest")]
     if user_signed_in?
       @items[2]=[tr("Your network", "view/user_contacts/_nav"), url_for(controller: "network", action: "following")]
       if false and current_instance.has_twitter_enabled?
         @items[3]=[tr("Twitterers", "view/network/_nav"), url_for(:controller => "network", :action => "twitterers")]
       end
     end
     @items
   end
end

