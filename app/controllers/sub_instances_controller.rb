class SubInstancesController < ApplicationController

  before_filter :authenticate_admin!
  before_filter :authenticate_root!, :only => [:new, :create, :destroy]

  def get_layout
    if action_name=="setup_status"
      return Instance.current.layout_for_subscriptions
    else
      return Instance.current.layout
    end
  end

  def setup_status
    respond_to do |format|
      format.js {
        unless SubInstance.current.setup_in_progress?
          render :update do |page|
            if SubInstance.current.subscription_enabled?
              if @current_subscription = SubInstance.current.subscription and @current_subscription.active?
                page << "window.location = '/subscription_accounts/users'"
              else
                page << "window.location = '/'"
              end
            end
          end
        end
      }
      format.html {
        unless SubInstance.current.setup_in_progress?
          if SubInstance.current.subscription_enabled?
            if @current_subscription = SubInstance.current.subscription and @current_subscription.active?
              redirect_to "/subscription_accounts/users"
            else
              redirect_to "/"
            end
          end
        end
      }
    end
  end

  def index
    @page_title = tr("SubInstance with {instance_name}", "controller/sub_instances", :instance_name => current_instance.name)
#    if user_signed_in? and current_user.attribute_present?("sub_instance_id")
#      redirect_to 'http://' + current_user.sub_instance.short_name + '.' + current_instance.base_url + edit_sub_instance_path(current_user.sub_instance)
#    end
    @sub_instance = SubInstance.new
  end

  # GET /sub_instances/1
  # GET /sub_instances/1.xml
  def show
    @sub_instance = SubInstance.find(params[:id])
    @page_title = @sub_instance.name
    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @sub_instance.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @sub_instance.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /sub_instances/new
  # GET /sub_instances/new.xml
  def new
    @page_title = tr("SubInstance with {instance_name}", "controller/sub_instances", :instance_name => current_instance.name)
    @sub_instance = SubInstance.new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /sub_instances/1/edit
  def edit
    @sub_instance = SubInstance.find(params[:id])
    @page_title = tr("Edit", "controller/sub_instances")
  end

  # GET /sub_instances/1/email
  def email
    @sub_instance = SubInstance.find(params[:id])
    @page_title = tr("Email list settings", "controller/sub_instances")
  end

  # POST /sub_instances
  # POST /sub_instances.xml
  def create
    @sub_instance = SubInstance.new(params[:sub_instance])
    @sub_instance.ip_address = request.remote_ip
    @sub_instance.short_name = @sub_instance.short_name.downcase
    @page_title = tr("New {instance_name} created", "controller/sub_instances", :instance_name => current_instance.name)
    respond_to do |format|
      if @sub_instance.save
        #create_new_tags(@sub_instance.required_tags.split(','))
        #@sub_instance.register!
        current_user.update_attribute(:sub_instance_id,@sub_instance.id)
        #@sub_instance.activate!
        flash[:notice] = tr("Thanks for registering with us!", "controller/sub_instances")
        session[:goal] = 'sub_instance'
        format.html { redirect_to 'http://' + @sub_instance.short_name + '.' + current_instance.base_url + picture_sub_instance_path(@sub_instance)}
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /sub_instances/1
  # PUT /sub_instances/1.xml
  def update
    @sub_instance = SubInstance.find(params[:id])
    @page_title = tr("SubInstance settings", "controller/sub_instances")
    params[:sub_instance].delete(:lock_users_to_instance)
    respond_to do |format|
      if @sub_instance.update_attributes(params[:sub_instance])
        create_new_tags(@sub_instance.required_tags.split(',')) if @sub_instance.required_tags
        flash[:notice] = tr("Saved settings", "controller/sub_instances")
        format.html { 
          if not @sub_instance.has_picture?
            redirect_to picture_sub_instance_path(@sub_instance)
          elsif params[:sub_instance][:name]
            redirect_to :action => "edit"
          else
            redirect_to :action => "email"
          end
        }
      else
        format.html { 
          if params[:sub_instance][:name]
            render :action => "edit" 
          else # send them to the sub_instance email update
            render :action => "email"
          end
        }
      end
    end
  end
  
  def picture
    @sub_instance = SubInstance.find(params[:id])
    @page_title = tr("Upload sub_instance logo", "controller/sub_instances")
  end

  def picture_save
    @sub_instance = SubInstance.find(params[:id])
    respond_to do |format|
      if @sub_instance.update_attributes(params[:sub_instance])
        flash[:notice] = tr("Picture uploaded successfully", "controller/sub_instances")
        format.html { redirect_to(:action => :picture) }
      else
        format.html { render :action => "picture" }
      end
    end
  end

  # DELETE /sub_instances/1
  # DELETE /sub_instances/1.xml
  def destroy
    @sub_instance = SubInstance.find(params[:id])
    @sub_instance.destroy

    respond_to do |format|
      format.html { redirect_to(sub_instances_url) }
    end
  end

  private

  def create_new_tags(tags)
    @sub_instance.required_tags.split(',').each do |tag|
      next if Tag.find_by_name(tag)
      Tag.create(name: tag)
    end
  end

end
