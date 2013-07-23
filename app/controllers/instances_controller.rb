class InstancesController < ApplicationController

  before_filter :authenticate_root!
  
  def authorized?
    (current_user.is_admin? and current_instance.id == params[:id]) or
    (current_user.is_root? and current_instance.id == params[:id])
  end

  # GET /instances/1/edit
  def edit
    @instance = Instance.find(params[:id])
    @page_title = tr("{instance_name} settings", "controller/instances", :instance_name => current_instance.name)
  end
  
  def apis
    @instance = Instance.find(params[:id])
    @page_title = tr("Third Party API settings", "controller/instances", :instance_name => current_instance.name)
  end

  # PUT /instances/1
  # PUT /instances/1.xml
  def update
    @instance = Instance.find(params[:id])
    @page_title = tr("{instance_name} settings", "controller/instances", :instance_name => current_instance.name)
    respond_to do |format|
      if @instance.update_attributes(params[:instance])
        flash[:notice] = tr("Saved {instance_name} settings", "controller/instances", :instance_name => current_instance.name)
        format.html { redirect_to edit_instance_url(current_instance) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

end
