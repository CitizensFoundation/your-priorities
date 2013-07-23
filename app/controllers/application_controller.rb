# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'will_paginate/array'
require 'whitelist'

class ApplicationController < ActionController::Base

  include FaceboxRender

  include Facebooker2::Rails::Controller

  require_dependency "activity.rb"
  require_dependency "relationship.rb"   
  require_dependency "capital.rb"

  helper :all # include all helpers, all the time
  
  # Make these methods visible to views as well
  helper_method :instance_cache, :current_sub_instance, :current_user_endorsements, :current_idea_ids, :current_following_ids, :current_ignoring_ids, :current_instance, :current_tags, :is_robot?, :js_help

  before_filter :clear_thread_current
  #before_filter :action_whitelist_filter
  before_filter :current_sub_instance
  before_filter :check_user
  before_filter :check_for_localhost
  before_filter :setup_geoblocking
  before_filter :check_subdomain
  before_filter :check_geoblocking

  before_filter :authenticate_http_if_locked

  before_filter :check_auto_authentication

  before_filter :set_user_return_to
  before_filter :clear_omniauth_data

  before_filter :load_actions_to_publish, :unless => [:is_robot?]
  before_filter :check_blast_click, :unless => [:is_robot?]
  before_filter :check_idea, :unless => [:is_robot?]
  before_filter :check_referral, :unless => [:is_robot?]
  before_filter :check_suspension, :unless => [:is_robot?]
  before_filter :check_google_translate_setting
  before_filter :check_missing_user_parameters, :except=>[:destroy]

  before_filter :setup_stages

  before_filter :setup_current_user_variable

  before_filter :setup_about_pages
  #before_filter :check_eula

  before_filter :check_subscription_plan
  before_filter :check_sub_instance_setup_status

  #after_filter :sub_instance_cookie_lock_down

  layout :get_layout

  protect_from_forgery

  def check_auto_authentication
    if params[:aa_secret]
      auto = AutoAuthentication.where(["created_at > ? AND secret = ? AND active = ?",Time.now-10.minutes,params[:aa_secret],true]).first
      if auto
        auto.active = false
        auto.save
        Rails.logger.info("Auto signing in #{auto.user.email}")
        sign_in auto.user, event: :authentication
      else
        Rails.logger.error("Failed to login with auto authentication")
      end
    end
  end

  def check_sub_instance_setup_status
    if SubInstance.current.subscription_enabled? and
       SubInstance.current.setup_in_progress?
      redirect_to :controller=>"sub_instances", :action=>"setup_status" unless action_name=="setup_status"
    end
  end

  def sub_instance_cookie_lock_down
    if SubInstance.current.lock_users_to_instance?
      request.session_options = request.session_options.dup
      request.session_options[:key] = "_#{SubInstance.last.short_name}_#{Instance.last.domain_name}_production"
      request.session_options[:domain] = "#{SubInstance.last.short_name}.#{Instance.last.domain_name}"
      request.session_options.freeze
    end
  end

  def clear_thread_current
    Thread.current[:current_user] = nil
    Thread.current[:instance] = nil
    Thread.current[:sub_instance] = nil
    Thread.current[:country_code] = nil
  end

  def check_subscription_plan
    #TODO Fix this mess
    if SubInstance.current.subscription_enabled?
      unless @current_subscription = SubInstance.current.subscription
        #TODO: Fix security hole here for users
        unless action_name=="select_plan" or controller_name=="subscriptions" or controller_name=="invitations" or request.fullpath.include?("/users/sign_in")
          if user_signed_in?
            redirect_to :controller=>"subscription_accounts", :action=>"select_plan"
          else
            flash[:error] = tr("You need to login to access this website", "controller/application")
            redirect_to "/users/sign_in"
            return false
          end
        end
      else
        @current_plan = @current_subscription.plan
        unless user_signed_in? or request.fullpath.include?("/users/sign_in") or request.fullpath.include?("/users/invitation/accept") or (controller_name=="invitations") or action_name=="setup_status"
          if @current_plan.private_instance
            flash[:error] = tr("You need to login to access this private website", "controller/application")
            redirect_to "/users/sign_in"
            return false
          end
        end
        if user_signed_in? and current_user.is_admin? and not @current_subscription.active and controller_name!="subscriptions" and action_name!="setup_status" and controller_name!="subscription_accounts"
          redirect_to :controller=>"subscriptions", :action=>"new", :plan_id=>@current_plan.id
        end
      end
    end
  end

  def setup_about_pages
    @about_pages = Page.order("title").all
  end

  def authenticate_http_if_locked
    if ENV['site_lock_username']
      authenticate_or_request_with_http_basic do |username, password|
        username == ENV['site_lock_username'] && password == ENV['site_lock_password']
      end
    elsif current_sub_instance.http_auth_username and current_sub_instance.http_auth_username!=""
      authenticate_or_request_with_http_basic do |username, password|
        username == current_sub_instance.http_auth_username && password == current_sub_instance.http_auth_password
      end
    end
  end

  def check_user
    if user_signed_in?
      unless controller_name=="users" and action_name=="additional_information"
        unless current_user.login and current_user.email
          redirect_to :controller=>"users", :action=>"additional_information"
        end
      end
    end
  end

  def check_eula
    if user_signed_in? and current_user.has_accepted_eula==false and controller_name!="users" and controller_name!="sessions"
      redirect_to :controller=>"users", :action=>"eula"
    end
  end

  def action_whitelist_filter
    Rails.logger.info("Checking whitelist for "+"#{"#{controller_name}_controller".camelize}##{action_name}")
    unless ACTION_WHITELIST.include?("#{"#{controller_name}_controller".camelize}##{action_name}")
      flash[:error] = tr("You are not authorized to access this page.", "controller/application")
      redirect_to "/"
    end
  end

  def tr(a,b="",c={})
    a.localized_text(c)
  end

  def setup_current_user_variable
    @current_user = current_user
  end

  def setup_stages
    @stage_name = current_sub_instance.stage_name if (current_sub_instance.stage_name and current_sub_instance.stage_name!="")
    @stage_description = current_sub_instance.stage_description if (current_sub_instance.stage_description and current_sub_instance.stage_description!="")
    @block_new_ideas = true if (current_sub_instance.block_new_ideas and current_sub_instance.block_new_ideas!="") or @geoblocked
    @block_points = true if (current_sub_instance.block_points and current_sub_instance.block_points!="") or @geoblocked
    @block_comments = true if (current_sub_instance.block_comments and current_sub_instance.block_comments!="") or @geoblocked
    @block_endorsements = true if (current_sub_instance.block_endorsements and current_sub_instance.block_endorsements!="") or @geoblocked
  end

  def redirect_to(options = {}, response_status = {})
    ::Rails.logger.error("Redirected by #{caller(1).first rescue "unknown"}")
    super(options, response_status)
  end

  protected

  def action_cache_path
    params.merge({:geoblocked=>@geoblocked, :host=>request.host, :country_code=>@country_code,
                  :locale=>session[:locale], :google_translate=>session[:enable_google_translate],
                  :have_shown_welcome=>session[:have_shown_welcome], 
                  :last_selected_language=>cookies[:last_selected_language],
                  :flash=>flash.map {|k,v| "#{v}" }.join.parameterize})
  end

  def do_action_cache?
    if user_signed_in?
      false
    elsif request.format.html?
      true
    else
      false
    end
  end
  
  def check_missing_user_parameters
    #if user_signed_in? and Instance.current and controller_name!="settings"
    #  unless current_user.email and current_user.my_gender and current_user.post_code and current_user.age_group
    #    flash[:notice] = "Please make sure you have registered all relevant information about you for this website."
    #    if request.format.js?
    #      render :update do |page|
    #        page.redirect_to :controller => "settings"
    #      end
    #      return false
    #    else
    #      redirect_to :controller=>"settings"
    #    end
    #  end
    #end
  end

  def check_for_localhost
    if false and Rails.env.development?
      unless user_signed_in?
        @user = User.unscoped.where(:is_admin=>true).first # 23 # find 23
        sign_in @user, event: :authentication
      end
    end
    if Rails.env.development?
      Thread.current[:localhost_override] = "#{request.host}:#{request.port}"
    end
  end

  def redirect_back_path
    Rails.logger.error "BACK: #{session[:user_return_to] || '/'}"
    session[:user_return_to] || '/' 
  end

  def set_user_return_to
    if ! devise_controller? && !%w[passwords sessions registrations].include?(controller_name) && request.get? && action_name != 'new'
      session[:user_return_to] = request.fullpath
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    stored_location_for(resource_or_scope) || '/' 
  end

  def after_sign_in_path_for(resource)
    if session["omniauth_data"]
      if not current_user.facebook_uid and session["omniauth_data"][:facebook_id]
        current_user.facebook_uid = session["omniauth_data"][:facebook_id]
        current_user.save(validate: false)
        flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Facebook"
      end
      session.delete("omniauth_data")
    end
    redirect_back_path
  end

  # remove omniauth data if omniauth users navigate away from the sign in/up
  # page without saving, allowing them to start over
  def clear_omniauth_data
   if session["omniauth_data"]
      if session["omniauth_data"][:new_user]
        session.delete("omniauth_data") if controller_name != 'registrations'
      else
        session.delete("omniauth_data") if controller_name != 'sessions'
      end
    end
  end

  def access_denied!
    flash[:error] = tr("You are not authorized to access this page.", "controller/application")
    redirect_to redirect_back_path
  end

  def authenticate_admin!
    if !user_signed_in?
      access_denied!
    elsif !current_user.is_admin? and !current_user.is_root?
      access_denied!
    end
  end

  def authenticate_root!
    if !user_signed_in?
      access_denied!
    elsif !current_user.is_root?
      access_denied!
    end
  end

  def authenticate_param_user!
    if !current_user.is_admin && !(user_signed_in? && current_user.id == params[:id].to_i)
      flash[:error] = tr("You are not authorized to access this page.", "controller/application")
      redirect_to new_user_session_path
    end
  end

  def add_devise_validation_errors_to_flash!(res = resource)
    if res && !res.errors.empty?
      flash[:error] = I18n.t("activerecord.errors.template.header",
                      count: res.errors.count,
                      model: res.class.model_name.human.downcase)
    end
  end

  def unfrozen_instance(object)
    eval "#{object.class}.where(:id=>object.id).first"
  end

  # Will either fetch the current sub_instance or return nil if there's no subdomain
  def current_sub_instance
    unless Rails.env.production?
      begin
        if params[:sub_instance_short_name]
          if params[:sub_instance_short_name].empty?
            session.delete(:set_sub_instance_id)
            SubInstance.current = @current_sub_instance = nil
          else
            @current_sub_instance = SubInstance.find_by_short_name(params[:sub_instance_short_name])
            SubInstance.current = @current_sub_instance
            session[:set_sub_instance_id] = @current_sub_instance.id
          end
        elsif session[:set_sub_instance_id]
          @current_sub_instance = SubInstance.find(session[:set_sub_instance_id])
          SubInstance.current = @current_sub_instance
        end
      end
    end
    @current_sub_instance ||= SubInstance.find_by_short_name(request.subdomains.first)
    @current_sub_instance ||= SubInstance.find_by_short_name("default")
    if @iso_country
      Rails.logger.info ("Setting sub instance to iso countr #{@iso_country.id}")
      @current_sub_instance ||= SubInstance.where(:iso_country_id=>@iso_country.id).first
    end
    @current_sub_instance ||= SubInstance.find_by_short_name("united-nations")
    SubInstance.current = @current_sub_instance
  end
  
  def setup_geoblocking
    if File.exists?(Rails.root.join("lib/geoip/GeoIP.dat"))
      @country_code = Thread.current[:country_code] = (session[:country_code] ||= GeoIP.new(Rails.root.join("lib/geoip/GeoIP.dat")).country(request.remote_ip)[3]).downcase
    else
      Rails.logger.error "No GeoIP.dat file"
    end
    @country_code = "ba" if @country_code == nil or @country_code == "--"
    @iso_country = IsoCountry.find_by_code(@country_code.upcase)
  end

  def check_geoblocking
    Rails.logger.info("#{controller_name}/#{action_name} - #{@country_code} - locale #{current_locale} - #{current_sub_instance.short_name} - #{current_user ? (current_user.email ? current_user.email : current_user.login) : "Anonymous"}")
    Rails.logger.info(request.user_agent)
    if SubInstance.current and SubInstance.current.geoblocking_enabled
      logged_in_user = current_user
      unless SubInstance.current.geoblocking_disabled_for?(@country_code)
        Rails.logger.info("Geoblocking enabled")
        @geoblocked = true unless Rails.env.development? or (current_user and current_user.is_admin?)
      end
      if logged_in_user and logged_in_user.geoblocking_disabled_for?(SubInstance.current)
        Rails.logger.info("Geoblocking disabled for user #{logged_in_user.login}")
        @geoblocked = false
      end
    end
    @geoblocked = false
    if @geoblocked
      #unless session["have_shown_geoblock_warning_#{@country_code}"]
        flash.now[:notice] = tr("This part of the website is only open for viewing in your country.","geoblocking")
      #  session["have_shown_geoblock_warning_#{@country_code}"] = true
      #end
    end
  end
  
  def current_locale
    if params[:locale]
      session[:locale] = params[:locale]
      cookies.permanent[:last_selected_language] = session[:locale]
      Rails.logger.debug("Set language from params")
    elsif not session[:locale]
      if cookies[:last_selected_language]
        session[:locale] = cookies[:last_selected_language]
        Rails.logger.debug("Set language from cookie")
      elsif @iso_country and @iso_country.default_locale
        session[:locale] = @iso_country.default_locale
        Rails.logger.debug("Set language from geoip")
      elsif SubInstance.current and SubInstance.current.default_locale
        session[:locale] = SubInstance.current.default_locale
        Rails.logger.debug("Set language from sub_instance")
      else
        session[:locale] = :en
      end
    else
      Rails.logger.debug("Set language from session")
    end
    session_locale = session[:locale]
    I18n.locale = session_locale
  end

  def check_google_translate_setting
    if params[:gt]
      if params[:gt]=="1"
        session[:enable_google_translate] = true
      else
        session[:enable_google_translate] = nil
      end
    end
    
    #@google_translate_enabled_for_locale = Tr8n::Config.current_language.google_key
  end
  
  def get_layout
    return false if not is_robot? and not current_instance
    return "basic" if not Instance.current
    return "hverfapottar_main" if controller_name == "about" and action_name=="show" and params[:id] == 'choose_sub_instance'
    return Instance.current.layout
  end

  def current_instance
    if @current_instance
      return @current_instance
    else
      @current_instance = Instance.last
    end
    return Instance.current = @current_instance
  end
  
  def current_user_endorsements
		@current_user_endorsements ||= current_user.endorsements.active.by_position.paginate(:include => :idea, :page => session[:endorsement_page], :per_page => 25)
  end
  
  def current_idea_ids
    return [] unless user_signed_in? and current_user.endorsements_count > 0
    @current_idea_ids ||= current_user.endorsements.active_and_inactive.collect{|e|e.idea_id}
  end  
  
  def current_following_ids
    return [] unless user_signed_in? and current_user.followings_count > 0
    @current_following_ids ||= current_user.followings.up.collect{|f|f.other_user_id}
  end
  
  def current_following_facebook_uids
    return [] unless user_signed_in? and current_user.followings_count > 0 and current_user.has_facebook?
    @current_following_facebook_uids ||= current_user.followings.up.collect{|f|f.other_user.facebook_uid}.compact
  end  
  
  def current_ignoring_ids
    return [] unless user_signed_in? and current_user.ignorings_count > 0
    @current_ignoring_ids ||= current_user.followings.down.collect{|f|f.other_user_id}    
  end
  
  def current_tags
    return [] unless current_instance.is_tags?
    @current_tags ||= Rails.cache.fetch('Tag.by_endorsers_count.all') { Tag.by_endorsers_count.all }
  end

  def load_actions_to_publish
    @user_action_to_publish = flash[:user_action_to_publish] 
    flash[:user_action_to_publish]=nil
  end  
  
  def check_suspension
    if user_signed_in? and current_user and current_user.status == 'suspended'
      self.current_user.forget_me! if user_signed_in?
      reset_session
      Thread.current[:current_user] = nil
      flash[:notice] = "This account has been suspended as a result after three warnings in regards to breaking the site rules."
      redirect_to redirect_back_path
      return  
    end
  end
  
  # they were trying to endorse a idea, so let's go ahead and add it and take htem to their ideas page immediately
  def check_idea
    return unless user_signed_in? and session[:idea_id]
    @idea = Idea.find(session[:idea_id])
    @value = session[:value].to_i
    if @idea
      if @value == 1
        @idea.endorse(current_user,request,@referral)
      else
        @idea.oppose(current_user,request,@referral)
      end
    end  
    session[:idea_id] = nil
    session[:value] = nil
  end

  def check_blast_click
    # if they've got a ?b= code, log them in as that user
    if params[:b] and params[:b].length > 2
      @blast = Blast.find_by_code(params[:b])
      if @blast and not user_signed_in?
        sign_in @blast.user
        @blast.increment!(:clicks_count)
      end
      redirect = request.path_info.split('?').first
      redirect = "/" if not redirect
      redirect_to redirect
      return
    end
  end

  def check_subdomain
    if not current_instance
      redirect_to :controller => "install"
      return
    end
    if not current_sub_instance and Rails.env == 'production' and request.subdomains.any? and not ['www','dev'].include?(request.subdomains.first) and current_instance.base_url != request.host
      redirect_to 'http://' + current_instance.base_url + request.path_info
      return
    end    
  end
  
  def check_referral
    if not params[:referral_id].blank?
      @referral = User.find(params[:referral_id])
    else
      @referral = nil
    end    
  end  

  def is_robot?
    return true if request.format == 'rss' or params[:controller] == 'pictures'
    request.user_agent =~ /\b(Baidu|Gigabot|Googlebot|libwww-perl|lwp-trivial|msnbot|SiteUptime|Slurp|WordPress|ZIBB|ZyBorg)\b/i
  end
  
  def bad_token
    flash[:error] = tr("Sorry, that last page already expired. Please try what you were doing again.", "controller/application")
    respond_to do |format|
      format.html { redirect_to request.referrer||'/' }
      format.js { redirect_from_facebox(request.referrer||'/') }
    end
  end
  
  def js_help
    JavaScriptHelper.instance
  end

  class JavaScriptHelper
    include Singleton
    include ActionView::Helpers::JavaScriptHelper
  end

  def setup_filter_dropdown
    setup_menu_items
    @sub_menu_items = @items
    Rails.logger.debug action_name

    if action_name == "index" and @items and not request.xhr? and controller_name != 'issues'
      Rails.logger.debug "index"
      selected = nil #DISABLED FEATURE cookies["selected_#{controller_name}_filter_id"].to_i
      Rails.logger.debug "cookie #{selected}"
      if selected and @sub_menu_items[selected]
        Rails.logger.debug "cookie"
        redirect_to @sub_menu_items[selected][1]
        return false
      else
        Rails.logger.debug "no cookie"
        redirect_to @sub_menu_items[1][1]
        return false
      end
    end

    selected_sub_menu_item_id, selected_sub_menu_item = find_menu_item_by_url(request.url)
    if selected_sub_menu_item
      @selected_sub_nav_name = selected_sub_menu_item[0]
      Rails.logger.debug "Saved submenu id #{selected_sub_menu_item_id}"
      @selected_sub_nav_item_id = selected_sub_menu_item_id
      if controller_name != 'issues'
        cookies["selected_#{controller_name}_filter_id"] = @selected_sub_nav_item_id
      end
    end
  end

  def find_menu_item_by_url(url)
    @items.each do |id,item|
      if url==item[1]
        return id,item
        break
      end
    end
  end
  protected
  def authenticate_inviter!
    if @current_plan and @current_plan.private_instance==true
      authenticate_admin!
    else
      authenticate_user!
    end
  end
end

