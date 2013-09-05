class SubscriptionAccount
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  def self.tr(a,b,c={})
    a.localized_text(c)
  end

  def tr(a,b,c={})
    a.localized_text(c)
  end

  attr_reader :user, :account, :sub_instance, :plan

  attr_accessor :terms

  delegate  :email, :email=, :password, :password=, :password_confirmation, :password_confirmation=,
            :persisted?, :id, :to => :user, :prefix => false, :allow_nil => false

  delegate  :short_name, :short_name=, :to => :sub_instance, :prefix => false, :allow_nil => false

  validates_presence_of     :user_name, :message => tr("Please specify your name", "here")
  validates_length_of       :user_name, :within => 2..60

  validates_presence_of     :instance_name, :message => tr("Please specify your instance name", "here")
  validates_length_of       :instance_name, :within => 4..80

  validates_presence_of     :short_name
  validates_length_of       :short_name, :within => 4..60
  #validates_uniqueness_of   :short_name

  validates_presence_of     :plan_id

  validates_presence_of     :password
  validates_length_of       :password, :within => 4..60

  validates_presence_of     :email
  validates_length_of       :email, :within => 3..100
  validates_format_of       :email, :with => /^[-^!$#%&'*+\/=3D?`{|}~.\w]+@[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])*(\.[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])*)+$/x

  validates_acceptance_of :terms

  validate :no_duplicate_short_name

  def no_duplicate_short_name
    if SubInstance.find_by_short_name(self.short_name)
      errors.add(:short_name, tr("this hostname is already taken","here"))
    end
  end

  def plan_id
    @plan.id
  end

  def plan_id=(id)
    @plan = Plan.find(id)
  end

  def instance_name
    @account.name
  end

  def instance_name=(name)
    @account.name = name
    @sub_instance.name = name
  end

  def user_name
    @user.login
  end

  def user_name=(name)
    @user.login = name
  end

  def initialize(sub_instance, user, account,plan, locale)
    @sub_instance = sub_instance
    @user = user
    @account = account
    @plan = plan
    @locale = locale
  end

  def attributes=(attributes)
    attributes.each { |k, v| self.send("#{k}=", v) }
  end

  def save!
    User.transaction do
      @user.save!(:validate=>false)
      @user.activate!
      @account.save!
      @sub_instance.save!

      @user.sub_instance_id = @sub_instance.id
      @user.is_admin = true
      @user.last_locale = @locale
      @user.save!(:validate=>false)

      @account.user_id = @user.id
      @account.save!

      subscription = Subscription.new
      subscription.account_id = @account.id
      subscription.plan_id = @plan.id
      if @plan.amount>0.0
        subscription.active = false
      else
        subscription.active = true
      end
      subscription.save
      @sub_instance.subscription_enabled = true
      @sub_instance.subscription = subscription
      @sub_instance.account_id = @account.id
      @sub_instance.lock_users_to_instance = true #TODO: Fix security risk here for people changing this parameter
      @sub_instance.setup_in_progress = true
      @sub_instance.save!
      #c=Category.create(:name=>"Test category", :description => "")
      #c.sub_instance_id=@sub_instance.id
      #c.save!
    end
    SubInstanceSetup.perform_async(@sub_instance.id,@user.id)
  end

  def post_user
  end
end
