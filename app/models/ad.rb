class Ad < ActiveRecord::Base

  acts_as_set_sub_instance :table_name=>"ads"

  scope :active, :conditions => "ads.status = 'active'"
  scope :inactive, :conditions => "ads.status in ('inactive','finished')"
  scope :finished, :conditions => "ads.status = 'finished'"
  scope :most_paid, :order => "ads.per_user_cost desc"
  scope :active_first, :order => "ads.status asc, ads.per_user_cost desc, ads.created_at desc"
  scope :by_recently_created, :order => "ads.created_at desc"
  scope :by_random, :order=>"RANDOM()"
  
  belongs_to :user
  belongs_to :idea
  
  has_many :shown_ads, :dependent => :destroy
  has_many :activities

  #acts_as_list :scope => "ads.status = 'active'"

  def validate
    if self.calculate_per_user_cost < 0.01
      errors.add("cost",tr("per member must be more than 0.01 social points",""))
    elsif self.cost > user.capitals_count
      errors.add("cost",tr("is more social points than you have.",""))
    end    
    errors.on("cost")
#    if idea.position < 26
#      errors.add(:base, "You can not purchase ads for ideas in the top 25 already.")
#    end
    if idea.is_buried?
      errors.add(:base, tr("You can not purchase ads for ideas that have been buried."))
    end    
  end
  
  validates_presence_of :show_ads_count
  validates_numericality_of :show_ads_count
  validates_presence_of :cost
  validates_numericality_of :cost
  validates_presence_of :content
  validates_length_of :content, :maximum => 90, :allow_nil => true, :allow_blank => true

  after_create :on_active_entry

  include Workflow
  workflow_column :status
  workflow do
    state :active do
      event :finish, transitions_to: :finished
      event :deactivate, transitions_to: :inactive
    end
    state :inactive do
      event :start, transitions_to: :active
      event :finish, transitions_to: :finished
    end
    state :finished do
      event :start, transitions_to: :active
    end
  end
  
  def on_finished_entry(new_state, event)
    self.finished_at = Time.now
    save(:validate => false)
    row = 0
    for a in Ad.active.most_paid.find(:all, :conditions => ["id <> ?",self.id])
      row += 1
      a.update_attribute(:position,row)
    end
  end
  
  def on_active_entry(new_state = nil, event = nil)
    row = 0
    for a in Ad.active.most_paid.all
      row += 1
      a.update_attribute(:position,row)
    end    
  end
  
  def on_inactive_entry(new_state, event)
    row = 0
    for a in Ad.active.most_paid.find(:all, :conditions => ["id <> ?",self.id])
      row += 1
      a.update_attribute(:position,row)
    end    
  end

  before_save :calculate_costs
  after_create :log_activity
  
  def calculate_costs
    self.per_user_cost = calculate_per_user_cost
    self.spent = self.shown_ads_count * self.per_user_cost
  end
  
  def calculate_per_user_cost
    return 0 if not self.attribute_present?("cost")
    return 0 if not self.attribute_present?("show_ads_count")    
    self.cost/self.show_ads_count.to_f
  end
  
  def log_activity
    user.increment(:ads_count)
    @activity = ActivityCapitalAdNew.create(:user => user, :idea => idea, :ad => self, :capital => CapitalAdNew.create(:sender => user, :amount => self.cost))
    if self.attribute_present?("content")
      @comment = @activity.comments.new
      @comment.content = content
      @comment.user = user
      if idea
        # if this is related to a idea, check to see if they endorse it
        e = idea.endorsements.active_and_inactive.find_by_user_id(user.id)
        @comment.is_endorser = true if e and e.is_up?
        @comment.is_opposer = true if e and e.is_down?
      end
      @comment.save(:validate => false)
    end
  end

  def idea_name
    idea.name if idea
  end
  
  def idea_name=(n)
    self.idea = Idea.find_by_name(n) unless n.blank?
  end
  
  def no_response_count
    shown_ads_count - yes_count - no_count
  end
  
  def has_content?
    attribute_present?("content")
  end

  # u= user, v=value, r=request
  def vote(u,v,r)
    sa = shown_ads.find_by_user_id(u.id)
    if sa and sa.value != v
      if sa.value == 1 and v == -1
        self.decrement!(:yes_count)
        self.increment!(:no_count)
      elsif sa.value == -1 and v == 1
        self.decrement!(:no_count)
        self.increment!(:yes_count)       
      elsif sa.value == 0 and v == -1
        self.increment!(:no_count) 
      elsif sa.value == 0 and v == 1
        self.increment!(:yes_count)
      elsif sa.value == -1 and v == 0
        self.decrement!(:no_count)
      elsif sa.value == 1 and v == 0
        self.decrement!(:yes_count)
      end
      sa.value = v
      sa.request = r
      sa.save
    elsif not sa
      sa = shown_ads.create(:user => u, :value => v, :request => r)
    end
    if sa and sa.value == 1
      idea.endorse(u,r,self.user)
      @activity = ActivityEndorsementNew.find_by_idea_id_and_user_id(self.idea.id,u.id, :order => "created_at desc")
      @activity.update_attribute(:ad_id,self.id) if @activity
    elsif sa and sa.value == -1
      idea.oppose(u,r,self.user)
      @activity = ActivityOppositionNew.find_by_idea_id_and_user_id(self.idea.id,u.id, :order => "created_at desc")
      @activity.update_attribute(:ad_id,self.id) if @activity
    end
  end

  def self.find_active_cached
    Rails.cache.fetch('Ad.active.all') { active.most_paid.all }
  end
  
end
