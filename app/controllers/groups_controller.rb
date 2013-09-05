class GroupsController < ApplicationController
  before_filter :authenticate_user!

                 #
  def suggest_user
    users = User.where("login LIKE ?","%#{params[:q]}%").limit(20).all.map{|u| {:value=>u.id.to_s,:name=>u.login,:image=>u.login}}
    respond_to do |format|
      format.json { render json: users }
    end
  end

  # GET /groups
  # GET /groups.json
  def index
    @groups = current_user.is_admin? ? Group.all : current_user.groups

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @groups }
    end
  end

  # GET /groups/1
  # GET /groups/1.json
  def show
    @group = group_with_access
    fetch_group_users

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @group }
    end
  end

  # GET /groups/new
  # GET /groups/new.json
  def new
    @group = Group.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @group }
    end
  end

  # GET /groups/1/edit
  def edit
    @group = group_with_access(:need_admin=>true)
    fetch_group_users
  end

  # POST /groups
  # POST /groups.json
  def create
    @group = Group.new(params[:group])

    respond_to do |format|
      if @group.save
        GroupsUser.create(:group_id=>@group.id, :user_id=>current_user.id, :is_admin=>true)
        format.html { redirect_to :action=>"edit", :id=>@group.id, notice: tr("Group was successfully created.","here") }
        format.json { render json: @group, status: :created, location: @group }
      else
        format.html { render action: "new" }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /groups/1
  # PUT /groups/1.json
  def update
    @group = group_with_access(:need_admin=>true)
    respond_to do |format|
      if @group.update_attributes(params[:group])
        params[:as_values_group_users] = params[:as_values_group_users][1..params[:as_values_group_users].length] if params[:as_values_group_users][0]==","
        params[:as_values_group_admin_users] = params[:as_values_group_admin_users][1..params[:as_values_group_admin_users].length] if params[:as_values_group_admin_users][0]==","
        if params[:as_values_group_admin_users].split(",").length>0
          GroupsUser.transaction do
            @group.users.clear
            params[:as_values_group_users].split(",").each do |u|
              GroupsUser.create(:group_id=>@group.id, :user_id=>u.to_i)
            end
            params[:as_values_group_admin_users].split(",").uniq.each do |u|
              GroupsUser.create(:group_id=>@group.id, :user_id=>u.to_i, :is_admin=>true)
            end
          end
          format.html { redirect_to @group, notice: 'Group was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @group.errors, status: :unprocessable_entity }
        end
      else
        format.html { render action: "edit" }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.json
  def destroy
    @group = group_with_access(:need_admin=>true)
    @group.destroy

    respond_to do |format|
      format.html { redirect_to groups_url }
      format.json { head :no_content }
    end
  end

  private

  def fetch_group_users
    if @group
      @group_users = GroupsUser.where(:group_id=>@group.id, :is_admin=>false).all.map{|u| {:value=>u.user.id.to_s,:name=>u.user.login,:image=>u.user.login}}.to_json.to_s
      @group_admin_users = GroupsUser.where(:group_id=>@group.id, :is_admin=>true).all.map{|u| {:value=>u.user.id.to_s,:name=>u.user.login,:image=>u.user.login}}.to_json.to_s
    end
  end

  def group_with_access(options={})
    group = Group.find(params[:id])
    if current_user.is_admin?
      group
    elsif options[:need_admin]
      if GroupsUser.where(:group_id=>group.id, :user_id=>current_user.id, :is_admin=>true)
        group
      else
        nil
      end
    else
      if GroupsUser.where(:group_id=>group.id, :user_id=>current_user.id)
        group
      else
        nil
      end
    end
  end
end
