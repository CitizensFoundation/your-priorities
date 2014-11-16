require 'digest/sha1'
require 'nokogiri'
require 'soap/rpc/driver'
require 'soap/wsdlDriver'
require 'base64'

class UsersController < ApplicationController

  skip_before_filter :set_user_return_to, only: :resend_activation
  before_filter :authenticate_user!, :only => [:accept_eula, :destroy, :additional_information, :request_validate_user_for_country, :validate_user_for_country, :resend_activation, :follow, :unfollow, :endorse, :subscriptions, :disable_facebook]
  before_filter :authenticate_param_user!, :only => [:resend_activation, :edit]
  before_filter :authenticate_admin!, :only => [:destroy_from_admin, :list_suspended, :suspend, :unsuspend, :impersonate, :update, :signups, :make_admin, :unmake_admin, :reset_password, :destroy]

  caches_action :show,
                :if => proc {|c| c.do_action_cache? },
                :cache_path => proc {|c| c.action_cache_path},
                :expires_in => 30.seconds

  def additional_information
    @page_title = tr("Additional needed information", "controller/users")
    @user = current_user
    if request.put?
      respond_to do |format|
        unless User.where(:email=>params[:user][:email]).first
          @user.email = params[:user][:email] if params[:user][:email]
        end
        @user.login = params[:user][:login] if params[:user][:login]
        @user.buddy_icon = params[:user][:buddy_icon] if params[:user][:buddy_icon]
        if @user.save(:validate=>false)
          Rails.logger.debug(params[:user])
          Rails.logger.debug(@user.inspect)
          flash[:notice] = tr("Saved settings for {user_name}", "controller/users", :user_name => @user.name)
          format.html { redirect_to "/" }
        else
          format.html { render :action => "additional_information" }
        end
      end
    end
  end

  def authenticate_from_island_is
    perform_island_is_token_authentication(params[:token],request)
  end

  def eula
    @page_title = tr("Terms of Use", "controller/users")
    if request.post? and current_user
      current_user.accepted_eula!
      redirect_to "/"
    end
  end

  def index
    if params[:term]
      @users = User.active.find(:all, :conditions => ["login LIKE ?", "#{h(params[:term])}%"], :order => "users.login asc")
    else
      @users = User.active.by_ranking.paginate :page => params[:page], :per_page => params[:per_page]  
    end
    respond_to do |format|
      format.html { redirect_to :controller => "network" }
      format.js { render :text => @users.collect{|p|p.login}.join("\n") }
      format.xml { render :xml => @users.to_xml(:include => [:top_endorsement, :referral, :sub_instance_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:top_endorsement, :referral, :sub_instance_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end
  
  def request_validate_user_for_country
    unless @iso_country
      flash[:error] = tr("Your country was not detected.", "controller/users", :user_name => @user.name)
      redirect_to '/'
    end
  end

  def validate_user_for_country
    email = params[:user][:email]
    user = User.find_by_email(email)
    if user and @iso_country
      user.add_iso_country_access!(@iso_country.code)
      flash[:error] = tr("{email} has allowed access to #{@iso_country.country_english_name}.", "controller/users", :user_name => @user.name)
      redirect_to '/'
    else
      flash[:error] = tr("{email} is not found.", "controller/users", :user_name => @user.name)
      redirect_to '/'
    end
  end
  
  def suspended
  end

  def list_suspended
    @users = User.suspended.paginate :page => params[:page], :per_page => params[:per_page] 
  end

  def disable_facebook
   #TODO: THis needs to be implemented
#    @user = current_user
#    @user.facebook_uid=nil
#    @user.save(:validate => false)
#    fb_cookie_destroy
    redirect_to '/'
  end
  
  def set_email
    @user = current_user
    flash[:notice]=nil
    if request.put?
      @user.email = params[:user][:email]
      @user.have_sent_welcome = true
      if @user.save
        @user.send_welcome
        redirect_to redirect_back_path
      else
        flash[:notice]=tr("Email not accepted", "controller/users")
        redirect_to "/set_email"
      end
    end
  end
  
  def subscriptions
    @subscription_user = current_user
    if request.put?
      TagSubscription.delete_all(["user_id = ?",current_user.id])
      Tag.all.each do |tag|
        tag_checkbox_id = "subscribe_to_tag_id_#{tag.id}"
        if params[:user][tag_checkbox_id]
          subscription = TagSubscription.new
          subscription.user_id = current_user.id
          subscription.tag_id = tag.id
          subscription.save
        end
      end
      Rails.logger.debug("Starting HASH #{params[:user].inspect}")
      params[:user].each do |hash_value,x|
        Rails.logger.debug(hash_value)
        if hash_value.include?("to_tag_id")
          Rails.logger.debug("DELETING: #{hash_value}")
          params[:user].delete(hash_value)
        end
      end
      Rails.logger.debug("After HASH #{params[:user].inspect}")
      if not current_user.reports_enabled and params[:user][:reports_enabled].to_i==1
        params[:user][:last_sent_report]=Time.now
      end
      current_user.update_attributes(params[:user])
      current_user.save(:validate => false)
      redirect_to "/"
    end
  end
  
  def edit
    @user = User.find(params[:id])
    redirect_to '/' and return if check_for_suspension
    @page_title = tr("Changing settings for {user_name}", "controller/users", :user_name => @user.name)
  end
  
  def update
    @user = User.find(params[:id])
    @page_title = tr("Changing settings for {user_name}", "controller/users", :user_name => @user.name)
    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = tr("Saved settings for {user_name}", "controller/users", :user_name => @user.name)
        @page_title = tr("Changing settings for {user_name}", "controller/users", :user_name => @user.name)
        format.html { redirect_to @user }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @page.errors, :status => :unprocessable_entity }
      end
    end
  end  
  
  def signups
    @user = User.find(params[:id])
    redirect_to '/' and return if check_for_suspension
    @page_title = tr("Email notifications for {user_name}", "controller/users", :user_name => @user.name)
    @rss_url = url_for(:only_path => false, :controller => "rss", :action => "your_notifications", :format => "rss", :c => @user.rss_code)
    @sub_instances = SubInstance.find(:all, :conditions => "is_optin = true and status = 'active' and id <> 3")
  end
    
  # GET /users/1
  # GET /users/1.xml
  def show
    @user = User.find(params[:id])
    redirect_to '/' and return if check_for_suspension
    @page_title = tr("{user_name} at {instance_name}", "controller/users", :user_name => @user.name, :instance_name => current_instance.name)
    #@ideas = @user.endorsements.active.by_position.find(:all, :include => :idea, :limit => 5)
    @ideas = Idea.unscoped.published.where(:user_id=>@user.id).paginate :page => params[:page], :per_page => params[:per_page]
    @endorsements = nil
    get_following
    if user_signed_in? # pull all their endorsements on the ideas shown
      @endorsements = Endorsement.unscoped.find(:all, :conditions => ["idea_id in (?) and user_id = ? and status='active'", @ideas.collect {|c| c.id},current_user.id])
    end
    respond_to do |format|
      format.html
      format.xml { render :xml => @user.to_xml(:methods => [:revisions_count], :include => [:top_endorsement, :referral, :sub_instance_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @user.to_json(:methods => [:revisions_count], :include => [:top_endorsement, :referral, :sub_instance_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  def ideas
    @user = User.find(params[:id])    
    redirect_to '/' and return if check_for_suspension
    @page_title = tr("{user_name} ideas at {instance_name}", "controller/users", :user_name => @user.name.possessive, :instance_name => current_instance.name)
    @ideas = @user.endorsements.active.by_position.paginate :include => :idea, :page => params[:page], :per_page => params[:per_page]
    @endorsements = nil
    get_following
    if user_signed_in? # pull all their endorsements on the ideas shown
      @endorsements = Endorsement.find(:all, :conditions => ["idea_id in (?) and user_id = ? and status='active'", @ideas.collect {|c| c.idea_id},current_user.id])
    end    
    respond_to do |format|
      format.html
      format.xml { render :xml => @ideas.to_xml(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end
  
  def activities
    @user = User.find(params[:id])
    redirect_to '/' and return if check_for_suspension
    get_following
    @page_title = tr("What {user_name} is doing at {instance_name}", "controller/users", :user_name => @user.name, :instance_name => current_instance.name)
    @activities = @user.activities.active.by_recently_created.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html # show.html.erb
      format.rss { render :template => "rss/activities" }
      format.xml { render :xml => @activities.to_xml(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end
  
  def comments
    @user = User.find(params[:id])
    redirect_to '/' and return if check_for_suspension
    @page_title = tr("{user_name} comments at {instance_name}", "controller/users", :user_name => @user.name.possessive, :instance_name => current_instance.name)
    @comments = @user.comments.published.by_recently_created.find(:all, :include => :activity).paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.rss { render :template => "rss/comments" }
      format.xml { render :xml => @comments.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @comments.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end  
  
  def discussions
    @user = User.find(params[:id])
    redirect_to '/' and return if check_for_suspension
    get_following
    @page_title = tr("{user_name} discussions at {instance_name}", "controller/users", :user_name => @user.name.possessive, :instance_name => current_instance.name)
    @activities = @user.activities.active.discussions.by_recently_created.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html { render :template => "users/activities" }
      format.xml { render :xml => @activities.to_xml(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end 
  
  def ads
    @user = User.find(params[:id])
    redirect_to '/' and return if check_for_suspension
    get_following
    @page_title = tr("{user_name} ads at {instance_name}", "controller/users", :user_name => @user.name.possessive, :instance_name => current_instance.name)
    @ads = @user.ads.active_first.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @ads.to_xml(:include => :idea, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ads.to_json(:include => :idea, :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end
  
  def capital
    @user = User.find(params[:id])
    redirect_to '/' and return if check_for_suspension
    get_following
    @page_title = tr("{user_name} {currency_name} at {instance_name}", "controller/users", :user_name => @user.name.possessive, :currency_name => current_instance.currency_name.downcase, :instance_name => current_instance.name)
    @activities = @user.activities.active.capital.by_recently_created.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html {
        render :template => "users/activities"
      }
      format.xml { render :xml => @activities.to_xml(:include => :capital, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => :capital, :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end  
  
  def points
    @user = User.find(params[:id])
    redirect_to '/' and return if check_for_suspension
    get_following
    @page_title = tr("{user_name} points at {instance_name}", "controller/users", :user_name => @user.name.possessive, :instance_name => current_instance.name)
    @points = @user.points.published.by_recently_created.paginate :page => params[:page], :per_page => params[:per_page]
    if user_signed_in? and @points.any? # pull all their qualities on the points shown
      @qualities = PointQuality.find(:all, :conditions => ["point_id in (?) and user_id = ? ", @points.collect {|c| c.id},current_user.id])
    end    
    respond_to do |format|
      format.html
      format.xml { render :xml => @points.to_xml(:include => [:idea,:other_idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @points.to_json(:include => [:idea,:other_idea], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end
  
  def stratml
    @user = User.find(params[:id])
    @page_title = tr("{user_name} ideas at {instance_name}", "controller/users", :user_name => @user.name.possessive, :instance_name => current_instance.name)
    @tags = @user.issues(500)
    respond_to do |format|
      format.xml # show.html.erb
    end    
  end

  def resend_activation
    @user = User.find(params[:id])
    redirect_to '/' and return if check_for_suspension
    UserMailer.confirmation_instructions(@user).deliver
    flash[:notice] = tr("Resent verification email to {email}", "controller/users", :email => @user.email)
    redirect_to redirect_back_path
  end  

  # POST /users/1/follow
  def follow
    @value = params[:value].to_i
    @user = User.find(params[:id])
    if @value == 1
      @following = current_user.follow(@user)
    else
      @following = current_user.ignore(@user)    
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          if params[:region] == 'user_left'
            page.replace_html 'user_' + @user.id.to_s + "_button",render(:partial => "users/button_small", :locals => {:user => @user, :following => @following})
          end          
        end
      }    
    end  
  end

  # POST /users/1/unfollow
  def unfollow
    @value = params[:value].to_i
    @user = User.find(params[:id])
    if @value == 1
      current_user.unfollow(@user)
    else
      current_user.unignore(@user)    
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          if params[:region] == 'user_left'
            page.replace_html 'user_' + @user.id.to_s + "_button",render(:partial => "users/button_small", :locals => {:user => @user, :following => nil})
          end          
        end
      }    
    end  
  end
  
  # GET /users/1/followers
  def followers
    @user = User.find(params[:id])
    return redirect_to '/' # and return if check_for_suspension
    get_following
    @page_title = tr("{count} people are following {user_name}", "controller/users", :user_name => @user.name, :count => @user.followers_count)      
    @followings = @user.followers.up.paginate :page => @page, :per_page => 50
    respond_to do |format|
      format.html
      format.xml { render :xml => @followings.to_xml(:include => [:user], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @followings.to_json(:include => [:user], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /users/1/ignorers
  def ignorers
    @user = User.find(params[:id])
    redirect_to '/' and return if check_for_suspension
    get_following    
    @page_title = tr("{count} people are ignoring {user_name}", "controller/users", :user_name => @user.name, :count => @user.ignorers_count)      
    @followings = @user.followers.down.paginate :page => @page, :per_page => 50
    respond_to do |format|
      format.html { render :action => "followers" }
      format.xml { render :xml => @followings.to_xml(:include => [:user], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @followings.to_json(:include => [:user], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end  
  
  # GET /users/1/following
  def following
    @user = User.find(params[:id])
    redirect_to '/' and return if check_for_suspension
    get_following
    @page_title = tr("{user_name} is following {count} people", "controller/users", :user_name => @user.name, :count => @user.followings_count)      
    @followings = @user.followings.up.paginate :page => @page, :per_page => 50
    respond_to do |format|
      format.html
      format.xml { render :xml => @followings.to_xml(:include => [:other_user], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @followings.to_json(:include => [:other_user], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /users/1/ignoring
  def ignoring
    @user = User.find(params[:id])
    redirect_to '/' and return if check_for_suspension
    get_following    
    @page_title = tr("{user_name} is ignoring {count} people", "controller/users", :user_name => @user.name, :count => @user.ignorings_count)      
    @followings = @user.followings.down.paginate :page => @page, :per_page => 50
    respond_to do |format|
      format.html { render :action => "following" }
      format.xml { render :xml => @followings.to_xml(:include => [:other_user], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @followings.to_json(:include => [:other_user], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end  

  # this is for loading up more endorsements in the left column
  def endorsements
    session[:endorsement_page] = (params[:page]||1).to_i
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html 'your_ideas_container', :partial => "ideas/yours"
        end
      }
    end
  end

  def order
    order = params[:your_ideas]
    endorsements = Endorsement.find(:all, :conditions => ["id in (?)", params[:your_ideas]], :order => "position asc")
    order.each_with_index do |id, position|
      if id
        endorsement = endorsements.detect {|e| e.id == id.to_i }
        new_position = (((session[:endorsement_page]||1)*25)-25)+position + 1
        if endorsement and endorsement.position != new_position
          endorsement.insert_at(new_position)
          endorsements = Endorsement.find(:all, :conditions => ["id in (?)", params[:your_ideas]], :order => "position asc")
        end
      end
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html 'your_ideas_container', :partial => "ideas/yours"
        end
      }
    end
  end

   # DELETE /user
  def destroy
    @user = User.find(current_user.id)
    @user.remove!
    self.current_user.forget_me
    cookies.delete :auth_token
    reset_session
    Thread.current[:current_user] = nil
    flash[:notice] = tr("Your account was deleted. Good bye!", "controller/settings")
    redirect_to "/" and return
  end

  def destroy_from_admin
    @user = User.find(params[:id])
    if @user.is_admin?
      flash[:error] = tr("Can't remove admin accounts","here")
    else
      flash[:notice] = tr("Account removed","here")
      @user.remove!
    end
    redirect_to :back
  end

  # PUT /users/1/suspend
  def suspend
    @user = User.find(params[:id])
    @user.suspend! 
    redirect_to(@user)
  end

  # PUT /users/1/unsuspend
  def unsuspend
    @user = User.find(params[:id])
    @user.unsuspend!
    flash[:notice] = tr("{user_name} has been reinstated", "controller/users", :user_name => @user.name)
    redirect_to request.referer
  end

  # this isn't actually used, but the current_user will endorse ALL of this user's ideas
  def endorse
    if not user_signed_in?
      session[:endorse_user] = params[:id]
      access_denied!
      return
    end
    @user = User.find(params[:id])
    for e in @user.endorsements.active
      e.idea.endorse(current_user,request,@referral) if e.is_up?
      e.idea.oppose(current_user,request,@referral) if e.is_down?
    end
    respond_to do |format|
      format.js { redirect_from_facebox(user_path(@user)) }        
    end    
  end
  
  def impersonate
    @user = User.find(params[:id])
    sign_in @user
    flash[:notice] = tr("You are now logged in as {user_name}", "controller/users", :user_name => @user.name)
    redirect_to @user
    return
  end
  
  def make_admin
    @user = User.find(params[:id])
    @user.is_admin = true
    @user.save(:validate => false)
    flash[:notice] = tr("{user_name} is now an Administrator", "controller/users", :user_name => @user.name)
    redirect_to :back
  end

  def unmake_admin
    if User.where(:is_admin=>true).count>1
      @user = User.find(params[:id])
      @user.is_admin = false
      @user.save(:validate => false)
      flash[:notice] = tr("{user_name} is now an Administrator", "controller/users", :user_name => @user.name)
    else
      flash[:notice] = tr("This is the last administrator and can't be removed", "controller/users", :user_name => @user.name)
    end
    redirect_to :back
  end

  private
  
    def get_following
      if user_signed_in?
        @following = @user.followers.find_by_user_id(current_user.id)      
      else
        @following = nil
      end
    end
    
    def check_for_suspension
      if @user.status == 'suspended'
        flash[:error] = tr("{user_name} is suspended", "controller/users", :user_name => @user.name)
        if user_signed_in? and current_user.is_admin?
        else
          return true
        end
      end
      if @user.status == 'removed'
        flash[:error] = tr("That user deleted their account", "controller/users")
        return true
      end
    end

  def perform_island_is_token_authentication(token,request)

    # Call island.is authentication service to verify the authentication token
    # Setup the island.is SOAP connection
    soap_url = "https://egov.webservice.is/sst/runtime.asvc/com.actional.soapstation.eGOVDKM_AuthConsumer.AccessPoint?WSDL"
    soap = SOAP::WSDLDriverFactory.new(soap_url).create_rpc_driver
    soap.options["protocol.http.basic_auth"] << [soap_url,ENV['ISLYKILL_USER'],ENV['ISLYKILL_PASSWORD']]
    Rails.logger.debug("BEFORE THE RESPONSE <> BEFORE THE RESPONSE")
    response = soap.generateSAMLFromToken(token,:token => token, :ipAddress=>request.remote_ip)
    Rails.logger.debug("THE RESPONSE < #{response} > THE RESPONSE")
    if response and response[0] and response[0].message="Success"
      elements = Nokogiri.parse(response[1])
      name = elements.root.xpath("//blarg:NameIdentifier", {'blarg' => 'urn:oasis:names:tc:SAML:1.0:assertion'}).first.text
      ssn = elements.root.xpath("//blarg:Attribute[@AttributeName='SSN']", {'blarg' => 'urn:oasis:names:tc:SAML:1.0:assertion'}).text
    else
      raise "Message was not a success #{response.inspect}"
    end
    # Get SAML response from island.is

    # SAML verification
    #saml_response_test          = Onelogin::Saml::Response.new(@response.saml)
    #saml_response_test.settings = saml_settings

    #Rails.logger.info("SAML Valid response: #{saml_response_test.validate!}")

    # Check and see if the response is a success


    #Rails.logger.error(response.saml)

    # Verify x509 cert from a known trusted source
    #known_raw_x509_cert = File.open("config/egov.webservice.is.cert")
    #known_x509_cert = OpenSSL::X509::Certificate.new(known_raw_x509_cert).to_s

    #test_x509_cert_source_txt_b64 = REXML::XPath.first(REXML::Document.new(@response.saml.to_s), "//ds:X509Certificate", { "ds"=>DSIG })
    #test_x509_cert_source_txt = Base64.decode64(test_x509_cert_source_txt_b64.text)

    #test_x509_cert = OpenSSL::X509::Certificate.new(test_x509_cert_source_txt).to_s

    #known_x509_cert_txt = known_x509_cert.to_s
    #test_x509_cert_txt = test_x509_cert.to_s

    #raise "Failed to verify x509 cert KNOWN #{known_x509_cert_txt} (#{known_x509_cert_txt.size}) |#{known_x509_cert_txt.encoding.name}| TEST #{test_x509_cert_txt} (#{test_x509_cert_txt.size}) |#{test_x509_cert_txt.encoding.name}|" unless known_x509_cert_txt == test_x509_cert_txt

    if ssn and ssn!=""
      if user = User.where(:ssn=>ssn).first
        sign_in user, event: :authentication
        redirect_to "/"
      else
        user = User.new
        user.ssn = ssn
        user.login = name
        user.save(:validate=>false)
        user.activate! unless user.active?
        sign_in user, event: :authentication
        redirect_to "/"
      end
    else
      raise "No SSN in island.is authentication"
    end
    Rails.logger.debug("Authentication successful for #{ssn} #{response.inspect}")
    return true
  end

end
