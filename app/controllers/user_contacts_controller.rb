class UserContactsController < ApplicationController
  
  before_filter :authenticate_user!
  before_filter :get_user
  
  # GET /users/1/contacts
  def index
    @page_title = tr("Find people you know at {instance_name}", "controller/contacts", :instance_name => current_instance.name)
    if @user.contacts_members_count > 0
      redirect_to members_user_contacts_path(@user) and return
    elsif @user.contacts_not_invited_count > 0
      redirect_to not_invited_user_contacts_path(@user) and return
    end
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def following
    @page_title = tr("People you're following at {instance_name}", "controller/contacts", :instance_name => current_instance.name)
    unless current_following_ids.empty?
      @users = User.active.by_capital.find(:all, :conditions => ["id in (?)",current_following_ids]) #:page => params[:page], :per_page => params[:per_page]
    end
  end
  
  def members
    @page_title = tr("Already members at {instance_name}", "controller/contacts", :instance_name => current_instance.name)
    @contacts = @user.contacts.active.members.not_following.find :all, :include => :other_user, :order => "users.created_at desc"
    if @contacts.empty?
      redirect_to not_invited_user_contacts_path(@user) and return
    end
  end  
  
  def not_invited
    @page_title = tr("Not members yet, go ahead and invite them.", "controller/contacts", :instance_name => current_instance.name)
    @contacts = @user.contacts.active.not_members.not_invited.with_email
  end
  
  def invited
    @page_title = tr("People you've invited to join {instance_name}", "controller/contacts", :instance_name => current_instance.name)
    @contacts = @user.contacts.active.not_members.invited.recently_updated.paginate :page => params[:page], :per_page => params[:per_page]
  end  

  # GET /users/1/contacts/new
  def new
    @page_title = tr("Invite people to join {instance_name}", "controller/contacts", :instance_name => current_instance.name)
    @contact = @user.contacts.new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # POST /users/1/contacts
  def create
    @contact = @user.contacts.new(params[:user_contact])
    @already_member = User.find(:all, :conditions => ["email = ? and status in ('active','pending','passive')",@contact.email])
    if @already_member.any?
      @already_member = @already_member[0] 
    else
      @already_member = nil
    end
    @existing = @user.contacts.find_by_email(@contact.email) unless @already_member
    respond_to do |format|
      if @already_member
        @user.follow(@already_member)
        format.js {
          render :update do |page|
            page.replace 'status', '<div id="status">' + tr("{user_name} is already a member", "controller/contacts", :user_name => @already_member.login) + '</div>'
            # page.visual_effect :fade, 'status', :duration => 3            
            page['user_contact_name'].value = ''
            page['user_contact_email'].value = ''            
            page['user_contact_name'].focus
          end
        }        
      elsif @existing
        format.js {
          render :update do |page|
            page.replace 'status', '<div id="status">' + tr("You already invited {user_name}", "controller/contacts", :user_name => @contact.name) + '</div>'
            # page.visual_effect :fade, 'status', :duration => 3            
            page['user_contact_name'].value = ''
            page['user_contact_email'].value = ''            
            page['user_contact_name'].focus
          end
        }
      elsif @contact.save
        @contact.invite!
        format.html { 
          flash[:notice] = tr("Invited {user_name}", "controller/contacts", :user_name => @contact.name)
          redirect_to(@contact) 
          }
        format.js {
          render :update do |page|
            page.replace 'status', '<div id="status">' + tr("Invited {user_name}", "controller/contacts", :user_name => @contact.name) + '</div>'
            # page.visual_effect :fade, 'status', :duration => 3
            page['user_contact_name'].value = ''
            page['user_contact_email'].value = ''            
            page['user_contact_name'].focus
            #if user_signed_in?
            #  page.insert_html :top, 'contacts', render(:partial => "contacts/item", :locals => { :contact => @contact })
            #  # page.visual_effect :highlight, 'contact_item_' + @contact.id.to_s
            #end
            page << "pageTracker._trackPageview('/goal/invitation')" if current_instance.has_google_analytics?
          end
        }
      else
        format.html { render :action => "new" }
        format.js {
          render :update do |page|
            page.replace_html 'status', @contact.errors.full_messages.join('<br/>')
            # page.visual_effect :fade, 'status', :duration => 3            
          end
        }        
      end
    end
  end
  
  # PUT /users/1/contacts/multiple
  def multiple
    @contacts = @user.contacts.find(:all, :conditions => ['id in (?)',params[:contact_ids]])
    respond_to do |format|
      format.js {
        render :update do |page|
          success = 0
          for contact in @contacts
            contact.invite!
            page.remove 'contact_' + contact.id.to_s
          end
          @user.reload
          if @user.contacts_not_invited_count == 0 # invited all their contacts
            flash[:notice] = tr("Thanks for inviting people to join {instance_name}. We'll send you an email when they join, and you'll earn 5{currency_short_name} too.", "controller/contacts", :currency_short_name => current_instance.currency_short_name, :instance_name => current_instance.name)
            page.redirect_to invited_user_contacts_path(@user)
          else
            page.hide 'status'            
            page.replace_html 'contacts_not_invited_count', @user.contacts_not_invited_count
            # page.visual_effect :highlight, 'contacts_not_invited_count'            
            page.replace_html 'contacts_invited_count', @user.contacts_invited_count
            # page.visual_effect :highlight, 'contacts_invited_count'                                    
          end
        end
      }    
    end
  end  
  
  private
  def get_user
    @user = User.find(params[:user_id])
    access_denied! unless current_user.id == @user.id
  end
end
