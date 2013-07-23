class Tag < ActiveRecord::Base

  acts_as_set_sub_instance :table_name=>"tags"

  scope :by_endorsers_count, :order => "tags.up_endorsers_count desc"

  scope :alphabetical, :order => "tags.name asc"
  scope :more_than_three_ideas, :conditions => "tags.ideas_count > 3"
  scope :with_ideas, :conditions => "tags.ideas_count > 0"
  
  scope :most_ideas, :conditions => "tags.ideas_count > 0", :order => "tags.ideas_count desc"
  scope :most_feeds, :conditions => "tags.feeds_count > 0", :order => "tags.feeds_count desc"

  scope :item_limit, lambda{|limit| {:limit=>limit}}

  scope :not_in_default_tags, lambda{|default_tags| {:conditions=>["tags.slug NOT IN (?)",(default_tags.empty? ? '' : default_tags)]}}

  has_many :activities, :dependent => :destroy
  has_many :taggings
  has_many :ideas, :through => :taggings, :source => :idea, :conditions => "taggings.taggable_type = 'Idea'"
                            
  belongs_to :top_idea, :class_name => "Idea", :foreign_key => "top_idea_id"
  belongs_to :rising_idea, :class_name => "Idea", :foreign_key => "rising_idea_id"
  belongs_to :controversial_idea, :class_name => "Idea", :foreign_key => "controversial_idea_id"
  belongs_to :official_idea, :class_name => "Idea", :foreign_key => "official_idea_id"
  
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :within => 1..60
  validates_length_of :title, :within => 1..60, :allow_blank => true, :allow_nil => true
  
  cattr_reader :per_page
  @@per_page = 15  
  
  before_save :update_slug
  
  after_create :expire_cache
  after_destroy :expire_cache

  def show_url
    if self.sub_instance_id
      Instance.current.homepage_url(self.sub_instance) + 'issues/' + self.slug
    else
      Instance.current.homepage_url + 'issues/' + self.slug
    end
  end
  
  def expire_cache
    Tag.expire_cache
  end
  
  def Tag.expire_cache
    Rails.cache.delete('Tag.by_endorsers_count.all')
  end
  
  def update_slug
    self.slug = self.to_url
    self.title = self.name unless self.attribute_present?("title")
  end
  
  def to_url
    "#{name.parameterize_full[0..60]}"
  end

  def to_s
    name
  end
  
  def self.all_dropdown_options
    out = ""
    Tag.all.each do |t|
      out+="<option>#{t.name}</option>"
    end
    out
  end
  
  # LIKE is used for cross-database case-insensitivity
  def self.find_or_create_with_like_by_name(name)
    find(:first, :conditions => ["name LIKE ?", name]) || create(:name => name)
  end
  
  def ==(object)
    super || (object.is_a?(Tag) && name == object.name)
  end
  
  def endorsements_count
    up_endorsers_count+down_endorsers_count
  end
  
  def count
    read_attribute(:count).to_i
  end
  
  def prompt_display
    return prompt if attribute_present?("prompt")
    return Instance.current.prompt
  end
  
  def published_idea_ids
    @published_idea_ids ||= Idea.published.tagged_with(self.name, :on => :issues).collect{|p| p.id}
  end
  
  def calculate_discussions_count
    Activity.active.discussions.for_all_users.by_recently_updated.count(:conditions => ["idea_id in (?)",published_idea_ids])
  end
  
  def calculate_points_count
    Point.published.count(:conditions => ["idea_id in (?)",published_idea_ids])
  end  
  
  def update_counts
    self.ideas_count = ideas.published.count
    self.points_count = calculate_points_count
    self.discussions_count = calculate_discussions_count
  end  
  
  def has_top_idea?
    attribute_present?("top_idea_id")
  end
  
  def rising_7days_count
    ideas.published.rising_7days.count
  end
  
  def flat_7days_count
    ideas.published.flat_7days.count
  end
  
  def falling_7days_count
    ideas.published.falling_7days.count
  end    
  
  def rising_7days_percent
    ideas.published.rising_7days.count.to_f/ideas_count.to_f
  end  
  
  def flat_7days_percent
    ideas.published.flat_7days.count.to_f/ideas_count.to_f
  end
  
  def falling_7days_percent
    ideas.published.falling_7days.count.to_f/ideas_count.to_f
  end    
  
  def rising_30days_count
    ideas.published.rising_30days.count
  end
  
  def flat_30days_count
    ideas.published.flat_30days.count
  end
  
  def falling_30days_count
    ideas.published.falling_30days.count
  end    
  
  def rising_24hr_count
    ideas.published.rising_24hr.count
  end
  
  def flat_24hr_count
    ideas.published.flat_24hr.count
  end
  
  def falling_24hr_count
    ideas.published.falling_24hr.count
  end  
  
  def subscribers
    @subscribers ||= User.find_by_sql(["
    select distinct users.*
    from users, endorsements, taggings
    where 
    endorsements.idea_id = taggings.taggable_id
    and taggings.tag_id = ?
    and taggings.taggable_type = 'Idea'
    and endorsements.status = 'active'
    and endorsements.user_id = users.id
    and users.report_frequency != 0
    and users.status in ('active','pending')",id])
  end
  
  def endorsers
    @endorsers ||= User.find_by_sql(["
    select distinct users.*
    from users, endorsements, taggings
    where 
    endorsements.idea_id = taggings.taggable_id
    and taggings.tag_id = ?
    and taggings.taggable_type = 'Idea'
    and endorsements.status = 'active'
    and endorsements.value = 1
    and endorsements.user_id = users.id
    and users.status in ('active','pending')",id])
  end  
  
  def opposers
    @opposers ||= User.find_by_sql(["
    select distinct users.*
    from users, endorsements, taggings
    where 
    endorsements.idea_id = taggings.taggable_id
    and taggings.tag_id = ?
    and taggings.taggable_type = 'Idea'
    and endorsements.status = 'active'
    and endorsements.value = -1
    and endorsements.user_id = users.id
    and users.status in ('active','pending')",id])
  end  
end
