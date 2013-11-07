class SubscriptionAccountsController < ApplicationController

  before_filter :authenticate_admin!, :only=>[:select_plan, :users]
  before_filter :authenticate_root!, :except=>[:new,:create,:select_plan, :users, :about]
  before_filter :setup_plans

  def get_layout
    unless action_name=="users"
      return Instance.current.layout_for_subscriptions
    else
      return Instance.current.layout
    end
  end

  def users
    @users = User.active.paginate :page => params[:page], :per_page => params[:per_page]
  end

  def select_plan
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @plans }
    end
  end

  # GET /subscription_accounts
  # GET /subscription_accounts.json
  def index
    @accounts = Account.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @accounts }
    end
  end

  # GET /subscription_accounts/1
  # GET /subscription_accounts/1.json
  def show
    @account = Account.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @account }
    end
  end

  # GET /subscription_accounts/new
  # GET /subscription_accounts/new.json
  def new
    @account = SubscriptionAccount.new(SubInstance.new, User.new, Account.new, Plan.new, I18n.locale)

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @account }
    end
  end

  # GET /subscription_accounts/1/edit
  def edit
    @account = Account.find(params[:id])
  end

  # POST /subscription_accounts
  # POST /subscription_accounts.json
  def create
    @account = SubscriptionAccount.new(SubInstance.new, User.new, Account.new, Plan.new, I18n.locale)
    @account.attributes = params[:subscription_account]
    respond_to do |format|
      if @account.valid?
        @account.save!
        if @account.sub_instance.subscription.plan.amount>0.0
          format.html { redirect_to @account.sub_instance.show_url_with_auto_auth(AutoAuthentication.create_with_secret!(@account.user)), notice: tr("Account was successfully created.","here") }
        else
          format.html { redirect_to @account.sub_instance.show_users_url_with_auto_auth(AutoAuthentication.create_with_secret!(@account.user)), notice: tr("Account was successfully created.","here") }
        end
        format.json { render json: @account, status: :created, location: @account }
      else
        format.html { render action: "new" }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /subscription_accounts/1
  # PUT /subscription_accounts/1.json
  def update
    @account = Account.find(params[:id])

    respond_to do |format|
      if @account.update_attributes(params[:account])
        format.html { redirect_to "/", notice: 'Account was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /subscription_accounts/1
  # DELETE /subscription_accounts/1.json
  def destroy
    @account = Account.find(params[:id])
    @account.destroy

    respond_to do |format|
      format.html { redirect_to accounts_url }
      format.json { head :no_content }
    end
  end

private

  def setup_plans
    @private_plans = Plan.where(:private_instance=>true, :active=>true).order(:max_users).all
    @public_plans = Plan.where(:private_instance=>false, :active=>true).order(:max_users).all
  end
end
