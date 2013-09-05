class SubscriptionsController < ApplicationController
  before_filter :authenticate_admin!
  before_filter :authenticate_root!, :only => [:index, :destroy ]

  def get_layout
    return Instance.current.layout_for_subscriptions
  end

  # GET /subscriptions
  # GET /subscriptions.json
  def index
    @subscriptions = Subscription.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @subscriptions }
    end
  end

  # GET /subscriptions/1
  # GET /subscriptions/1.json
  def show
    @subscription = Subscription.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @subscription }
    end
  end

  # GET /subscriptions/new
  # GET /subscriptions/new.json
  def new
   plan = Plan.find(params[:plan_id]) 
   @subscription = plan.subscriptions.build

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @subscription }
    end
  end

  # GET /subscriptions/1/edit
  def edit
    @subscription = Subscription.find(params[:id])
  end

  # POST /subscriptions
  # POST /subscriptions.json
  def create
    @subscription = Subscription.new(params[:subscription])
    @subscription.account_id = SubInstance.current.account_id
    respond_to do |format|
      if @subscription.plan.amount > 0.0
        result = @subscription.save_with_payment(current_user,@current_subscription)
      else
        @subscription.cancel_current_subscription(@current_subscription) if @current_subscription
        result = @subscription.save
      end
      if result
        @subscription.active = true
        @subscription.save
        sub_instance = SubInstance.current
        sub_instance.reload
        sub_instance.subscription_id = @subscription.id
        sub_instance.save!
        format.html { redirect_to "/subscription_accounts/users", notice: tr("Subscription was successfully created.","here") }
        format.json { render json: @subscription, status: :created, location: @subscription }
      else
        format.html { render action: "new" }
        format.json { render json: @subscription.errors, status: :unprocessable_entity }
      end
    end
  end

  def update_plan
    @subscription = Subscription.find(params[:id])
    @plan = Plan.find(params[:plan_id])
    if @subscription.plan.id != @plan.id
      @subscription.plan = @plan
      if @plan.amount>0.0
        @subscription.active = false
      else
        @subscription.cancel_current_subscription(@current_subscription) if @current_subscription
        @subscription.active = true
      end
    end
    respond_to do |format|
      if @plan.amount>0.0
        format.html { redirect_to :action=>"new", :plan_id=>@plan.id }
      elsif @subscription.save
        format.html { redirect_to SubInstance.current.show_url, :notice=> tr("Subscription was successfully update.","here") }
        format.json { render json: @subscription, status: :created, location: @subscription }
      else
        format.html { redirect_to SubInstance.current.show_url, error: tr("Subscription could not be updated.","here") }
        format.json { render json: @subscription, status: :error, location: @subscription }
      end
    end
  end

    # PUT /subscriptions/1
  # PUT /subscriptions/1.json
  def update
    @subscription = Subscription.find(params[:id])

    respond_to do |format|
      if @subscription.update_attributes(params[:subscription])
        format.html { redirect_to @subscription, notice: 'Subscription was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @subscription.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /subscriptions/1
  # DELETE /subscriptions/1.json
  def destroy
    @subscription = Subscription.find(params[:id])
    @subscription.destroy

    respond_to do |format|
      format.html { redirect_to subscriptions_url }
      format.json { head :no_content }
    end
  end
end
