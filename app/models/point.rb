class Point < ActiveRecord::Base

  acts_as_set_sub_instance :table_name=>"points"

  scope :published, :conditions => "points.status = 'published'"
  scope :by_helpfulness, :order => "points.score desc"
  scope :by_endorser_helpfulness, :conditions => "points.endorser_score > 0", :order => "points.endorser_score desc"
  scope :by_neutral_helpfulness, :conditions => "points.neutral_score > 0", :order => "points.neutral_score desc"    
  scope :by_opposer_helpfulness, :conditions => "points.opposer_score > 0", :order => "points.opposer_score desc"
  scope :up, :conditions => "points.endorser_score > 0"
  scope :neutral, :conditions => "points.neutral_score > 0"
  scope :down, :conditions => "points.opposer_score > 0"    
  scope :up_value, :conditions => "points.value > 0"
  scope :neutral_value, :conditions => "points.value = 0"
  scope :down_value, :conditions => "points.value < 0"    
  scope :by_recently_created, :order => "points.created_at desc"
  scope :by_recently_updated, :order => "points.updated_at desc"  
  scope :flagged, :conditions => "points.flags_count > 0"
  scope :published, :conditions => "points.status = 'published'"
  scope :unpublished, :conditions => "points.status not in ('published','abusive')"

  scope :revised, :conditions => "revisions_count > 1"
  scope :top, :order => "points.score desc"
  scope :one, :limit => 1
  scope :five, :limit => 5
  scope :since, lambda{|time| {:conditions=>["questions.created_at>?",time]}}

  belongs_to :user
  belongs_to :idea
  belongs_to :other_idea, :class_name => "Idea"
  belongs_to :revision # the current revision
  
  has_many :revisions, :dependent => :destroy
  has_many :activities, :dependent => :destroy, :order => "activities.created_at desc"

  has_many :author_users, :through => :revisions, :select => "distinct users.*", :source => :user, :class_name => "User"
  
  has_many :point_qualities, :order => "created_at desc", :dependent => :destroy
  has_many :helpfuls, :class_name => "PointQuality", :conditions => "value = true", :order => "created_at desc"
  has_many :unhelpfuls, :class_name => "PointQuality", :conditions => "value = false", :order => "created_at desc"
  
  has_many :capitals, :as => :capitalizable, :dependent => :nullify

  has_many :notifications, :as => :notifiable, :dependent => :destroy

  def author_user
    self.author_users.select("revisions.*, users.*").order("revisions.created_at ASC").first
  end

  def last_author
    self.author_users.select("revisions.*, users.*").order("revisions.created_at DESC").last
  end
  
  def category_name
    if idea_id and Idea.unscoped.find(idea_id).category
      Idea.unscoped.find(idea_id).category.name
    else
      'No category'
    end
  end
  
  cattr_reader :per_page
  @@per_page = 15  
  
  def to_param
    "#{id}-#{name.parameterize_full}"
  end  
  
  after_destroy :delete_point_quality_activities
  before_destroy :remove_counts
#  after_commit :setup_revision
  before_save :ensure_request_and_user_are_set
  
  validates_length_of :name, :within => 5..60, :too_long => tr("has a maximum of 60 characters", "model/point"), 
                                               :too_short => tr("please enter more than 5 characters", "model/point")
    #validates_uniqueness_of :name
  # this is actually just supposed to be 500, but bumping it to 520 because the javascript counter doesn't include carriage returns in the count, whereas this does.
  validates_length_of :content, :within => 5..1000, :too_long => tr("has a maximum of 500 characters", "model/point"),
                                                   :too_short => tr("please enter more than 5 characters", "model/point")
  validates_inclusion_of :value, :in => [-1, 1], :message=>tr("select support or against", "model/point")

  after_create :on_published_entry

  include Workflow
  workflow_column :status
  workflow do
    state :published do
      event :remove, transitions_to: :removed
      event :bury, transitions_to: :buried
      event :remove, transitions_to: :removed
    end
    state :draft do
      event :publish, transitions_to: :published
      event :remove, transitions_to: :removed
      event :bury, transitions_to: :buried
    end
    state :removed do
      event :bury, transitions_to: :buried
      event :unremove, transitions_to: :published, meta: { validates_presence_of: [:published_at] }
      event :unremove, transitions_to: :draft
    end
    state :buried do
      event :remove, transitions_to: :removed
      event :unbury, transitions_to: :published, meta: { validates_presence_of: [:published_at] }
      event :unbury, transitions_to: :draft
    end
  end

  def do_abusive!(reason)
    self.last_author.do_abusive!(notifications,reason)
    self.update_attribute(:flags_count, 0)
  end

  def flag_by_user(user)
    self.increment!(:flags_count)
    for r in User.active.admins
      notifications << NotificationPointFlagged.new(:sender => user, :recipient => r)    
    end
  end

  def on_published_entry(new_state = nil, event = nil)
    self.published_at = Time.now
    ensure_request_and_user_are_set
    add_counts
    save(:validate => false) if persisted?
    idea.save(:validate => false)
  end
  
  def on_removed_entry(new_state, event)
    remove_counts
    activities.active.each do |a|
      a.remove!
    end
    #capital_earned = capitals.sum(:amount)
    #if capital_earned != 0
    #  self.capitals << CapitalPointHelpfulDeleted.new(:recipient => user, :amount => (capital_earned*-1))
    #end
    idea.save(:validate => false)
    for r in revisions
      r.remove!
    end
  end

  def setup_revision
    Revision.create_from_point(self)
  end
 
  def ensure_request_and_user_are_set
    if self.idea
      self.ip_address = self.idea.ip_address if not self.ip_address
      self.user_agent = self.idea.user_agent if not self.user_agent
      self.user_id = self.idea.user_id if not self.user_id
      self.user = self.idea.user if not self.user
      Rails.logger.debug("SELF PRIORITY: #{self.idea.inspect}")
    else
      Rails.logger.error("No Idea for point id: #{self.id}")
      puts "No Idea for point id: #{self.id}"
    end
  end
  
  def on_buried_entry(new_state, event)
    remove_counts
    idea.save(:validate => false)
  end
  
  def add_counts
    idea.up_points_count += 1 if is_up?
    idea.down_points_count += 1 if is_down?
    idea.neutral_points_count += 1 if is_neutral?
    idea.points_count += 1
    user.increment!(:points_count)    
  end
  
  def remove_counts
    idea.up_points_count -= 1 if is_up?
    idea.down_points_count -= 1 if is_down?
    idea.neutral_points_count -= 1 if is_neutral?
    idea.points_count -= 1
    user.decrement!(:points_count)        
  end
  
  def delete_point_quality_activities
    qs = Activity.find(:all, :conditions => ["point_id = ? and type in ('ActivityPointHelpfulDelete','ActivityPointUnhelpfulDelete')",self.id])
    for q in qs
      q.destroy
    end
  end

  def name_with_type
    return name unless is_down?
    "[#{tr("Against", "model/point")}] " + name
  end

  def text
    s = name_with_type
    s += "\r\nIn support of " + other_idea.name if has_other_idea?
    s += "\r\n" + content
    s += "\r\nSource: " + website_link if has_website?
    return s
  end

  def authors
    revisions.count(:group => :user, :order => "count_all desc")
  end
  
  def editors
    revisions.count(:group => :user, :conditions => ["revisions.user_id <> ?", user_id], :order => "count_all desc")
  end  
  
  def is_up?
    value > 0
  end
  
  def is_down?
    value < 0
  end
  
  def is_neutral?
    value == 0
  end
  
  def is_removed?
    status == 'removed'
  end

  def is_published?
    ['published'].include?(status)
  end
  alias :is_published :is_published?
  
  auto_html_for(:content) do
    html_escape
    youtube :width => 330, :height => 210
    vimeo :width => 330, :height => 180
    link :target => "_blank", :rel => "nofollow"
  end  

  def calculate_score(tosave=false,current_endorsement=nil)
    old_score = self.score
    old_endorser_score = self.endorser_score
    old_opposer_score = self.opposer_score
    old_neutral_score = self.neutral_score
    self.score = 0
    self.endorser_score = 0
    self.opposer_score = 0
    self.neutral_score = 0
    for q in point_qualities.find(:all, :include => :user)
      #Rails.logger.debug("point_score_debug #{q.inspect} #{self.inspect}")
      if q.is_helpful?
        vote = q.user.quality_factor
      else
        vote = -q.user.quality_factor
      end
      self.score += vote
      if q.is_endorser?
        self.endorser_score += vote
      elsif q.is_opposer?
        self.opposer_score += vote        
      else
        self.neutral_score += vote
      end
    end

    if old_score != self.score and tosave
      self.save(:validate => false)
    end    
  end

  def opposers_helpful?
    opposer_score > 0
  end
  
  def endorsers_helpful?
    endorser_score > 0    
  end
  
  def neutrals_helpful?
    neutral_score > 0    
  end  

  def everyone_helpful?
    score > 0    
  end
  
  def helpful_endorsers_capital_spent
    capitals.sum(:amount, :conditions => "type = 'CapitalPointHelpfulEndorsers'")
  end

  def helpful_opposers_capital_spent
    capitals.sum(:amount, :conditions => "type = 'CapitalPointHelpfulOpposers'")
  end
  
  def helpful_undeclareds_capital_spent
    capitals.sum(:amount, :conditions => "type = 'CapitalPointHelpfulUndeclareds'")
  end  
  
  def helpful_everyone_capital_spent
    capitals.sum(:amount, :conditions => "type = 'CapitalPointHelpfulEveryone'")
  end  

  def idea_name
    idea.name if idea
  end
  
  def idea_name=(n)
    self.idea = Idea.find_by_name(n) unless n.blank?
  end
  
  def other_idea_name
    other_idea.name if other_idea
  end
  
  def other_idea_name=(n)
    self.other_idea = Idea.find_by_name(n) unless n.blank?
  end

  def has_other_idea?
    attribute_present?("other_idea_id")
  end
  
  def website_link
    return nil if self.website.nil?
    wu = website
    wu = 'http://' + wu if wu[0..3] != 'http'
    return wu    
  end  
  
  def has_website?
    attribute_present?("website")
  end
  
  def show_url
    if self.sub_instance_id
      Instance.current.homepage_url(self.sub_instance) + 'points/' + to_param
    else
      Instance.current.homepage_url + 'points/' + to_param
    end
  end
  
  def calculate_importance
  	PointImportanceScore.calculate_score(self.id)
  end

  def set_importance(user_id, score)
  	PointImportanceScore.update_or_create(self.id, user_id, score)
  end

  def idea
    Idea.unscoped.find(idea_id) if idea_id
  end
end
