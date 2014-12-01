class Idea < ActiveRecord::Base
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::UrlHelper

  #attr_accessible :category, :group, :issue_list, :description, :name

  is_impressionable :counter_cache => true

  acts_as_set_sub_instance :table_name=>"ideas"

  if Instance.current and Instance.current.is_suppress_empty_ideas?
    scope :published, :conditions => "ideas.status = 'published' and ideas.position > 0 and endorsements_count > 0"
  else
    scope :published, :conditions => "ideas.status = 'published'"
  end

  scope :published, :conditions => "ideas.status = 'published'"
  scope :unpublished, :conditions => "ideas.status not in ('published','abusive')"
  scope :not_removed, :conditions => "ideas.status <> 'removed'"
  scope :flagged, :conditions => "flags_count > 0"
  scope :alphabetical, :order => "ideas.name asc"
  scope :by_impressions_count, :order => "ideas.impressions_count desc"
  scope :by_most_discussed, :order => "points_count + discussions_count desc"
  scope :top_rank, :order => "ideas.score desc" # :conditions=>"position != 0"
  scope :top_three, :order => "ideas.score desc", :limit=>3

  scope :top_24hr, :conditions => "ideas.position_endorsed_24hr IS NOT NULL", :order => "ideas.position_endorsed_24hr desc"
  scope :top_7days, :conditions => "ideas.position_endorsed_7days IS NOT NULL", :order => "ideas.position_endorsed_7days desc"
  scope :top_30days, :conditions => "ideas.position_endorsed_30days IS NOT NULL", :order => "ideas.position_endorsed_30days desc"

  scope :not_top_rank, :conditions => "ideas.position > 25"
  scope :rising, :conditions => "ideas.trending_score > 0", :order => "ideas.trending_score desc"
  scope :falling, :conditions => "ideas.trending_score < 0", :order => "ideas.trending_score asc"
  scope :controversial, :conditions => "ideas.is_controversial = true", :order => "ideas.controversial_score desc"

  scope :category_filter, lambda{{:conditions => Thread.current[:category_id_filter] ? "ideas.category_id=#{Thread.current[:category_id_filter]}" : nil }}

  scope :rising_7days, :conditions => "ideas.position_7days_delta > 0"
  scope :flat_7days, :conditions => "ideas.position_7days_delta = 0"
  scope :falling_7days, :conditions => "ideas.position_7days_delta < 0"
  scope :rising_30days, :conditions => "ideas.position_30days_delta > 0"
  scope :flat_30days, :conditions => "ideas.position_30days_delta = 0"
  scope :falling_30days, :conditions => "ideas.position_30days_delta < 0"
  scope :rising_24hr, :conditions => "ideas.position_24hr_delta > 0"
  scope :flat_24hr, :conditions => "ideas.position_24hr_delta = 0"
  scope :falling_24hr, :conditions => "ideas.position_24hr_delta < 0"
  
  scope :finished, :conditions => "ideas.official_status in (-2,-1,2)"
  scope :successful, :conditions => "ideas.official_status = 2"
  scope :compromised, :conditions => "ideas.official_status = -991"
  scope :failed, :conditions => "ideas.official_status = -2"
  scope :in_progress, :conditions => "ideas.official_status in (-1,1)"

  scope :revised, :conditions => "idea_revisions_count > 1"
  scope :by_recently_revised, :joins => :idea_revisions, :order => "idea_revisions.created_at DESC"
  
  scope :by_user_id, lambda{|user_id| {:conditions=>["user_id=?",user_id]}}
  scope :item_limit, lambda{|limit| {:limit=>limit}}
  scope :only_ids, :select => "ideas.id"
  
  scope :alphabetical, :order => "ideas.name asc"
  scope :newest, :order => "ideas.created_at desc"
  scope :last_published, :order => "ideas.published_at desc, ideas.created_at desc"
  scope :tagged, :conditions => "(ideas.cached_issue_list is not null and ideas.cached_issue_list <> '')"
  scope :untagged, :conditions => "(ideas.cached_issue_list is null or ideas.cached_issue_list = '')", :order => "ideas.endorsements_count desc, ideas.created_at desc"

  scope :by_most_recent_status_change, :order => "ideas.status_changed_at desc"
  scope :by_random, :order => "RANDOM()"

  scope :item_limit, lambda{|limit| {:limit=>limit}}  
  
  belongs_to :user
  belongs_to :sub_instance
  belongs_to :category
  belongs_to :group
  belongs_to :idea_revision

  has_many :idea_revisions, :dependent => :destroy
  has_many :author_users, :through => :idea_revisions, :select => "distinct users.*", :source => :user, :class_name => "User"
  has_many :relationships, :dependent => :destroy
  has_many :incoming_relationships, :foreign_key => :other_idea_id, :class_name => "Relationship", :dependent => :destroy
  
  has_many :endorsements, :dependent => :destroy
  has_many :endorsers, :through => :endorsements, :conditions => "endorsements.status in ('active','inactive')", :source => :user, :class_name => "User"
  has_many :up_endorsers, :through => :endorsements, :conditions => "endorsements.status in ('active','inactive') and endorsements.value=1", :source => :user, :class_name => "User"
  has_many :down_endorsers, :through => :endorsements, :conditions => "endorsements.status in ('active','inactive') and endorsements.value=-1", :source => :user, :class_name => "User"

  has_many :points, :conditions => "points.status in ('published','draft')"
  accepts_nested_attributes_for :points

  has_many :my_points, :conditions => "points.status in ('published','draft')", :class_name => "Point"
  accepts_nested_attributes_for :my_points
  
  has_many :incoming_points, :foreign_key => "other_idea_id", :class_name => "Point"
  has_many :published_points, :conditions => "status = 'published'", :class_name => "Point", :order => "points.helpful_count-points.unhelpful_count desc"
  has_many :points_with_deleted, :class_name => "Point", :dependent => :destroy

  has_many :rankings, :dependent => :destroy
  has_many :activities, :dependent => :destroy

  has_many :charts, :class_name => "IdeaChart", :dependent => :destroy
  has_many :ads, :dependent => :destroy
  has_many :notifications, :as => :notifiable, :dependent => :destroy
  
  has_many :idea_status_change_logs, dependent: :destroy

  attr_accessor :idea_type

  cattr_reader :per_page
  @@per_page = 10

  acts_as_taggable_on :issues
  acts_as_list

  auto_html_for(:notes) do
    html_escape
    simple_format
    image
    youtube(:width => 330, :height => 210)
    vimeo(:width => 330, :height => 180)
    link :target => "_blank", :rel => "nofollow"
  end

  def category_name
    if category
      category.name
    else
      'No category'
    end
  end

  def help_with_this

  end

  validates_length_of :name, :within => 5..250, :too_long => tr("has a maximum of 200 characters", "model/idea"),
                                               :too_short => tr("please enter more than 5 characters", "model/idea")

  validates_length_of :description, :within => 10..550, :too_long => tr("has a maximum of 500 characters", "model/idea"),
                                                       :too_short => tr("please enter more than 10 characters", "model/idea")


  #validates_uniqueness_of :name, :if => Proc.new { |idea| idea.status == 'published' }
  validates :category_id, :presence => true

  after_create :on_published_entry

  include Workflow
  workflow_column :status
  workflow do
    state :published do
      event :remove, transitions_to: :removed
      event :bury, transitions_to: :buried
      event :deactivate, transitions_to: :inactive
    end
    state :passive do
      event :publish, transitions_to: :published
      event :remove, transitions_to: :removed
      event :bury, transitions_to: :buried
    end
    state :draft do
      event :publish, transitions_to: :published
      event :remove, transitions_to: :removed
      event :bury, transitions_to: :buried
      event :deactivate, transitions_to: :inactive
    end
    state :removed do
      event :bury, transitions_to: :buried
      event :unremove, transitions_to: :published, meta: { validates_presence_of: [:published_at] }
      event :unremove, transitions_to: :draft
    end
    state :buried do
      event :deactivate, transitions_to: :inactive
    end
    state :inactive do
      event :remove, transitions_to: :removed
    end
  end

  def get_position_score(time_since=nil)
    if time_since
      up = self.endorsements.where("status='active' AND created_at >= '#{time_since}' AND value=1").count
      down = self.endorsements.where("status='active' AND created_at >= '#{time_since}' AND value=-1").count
    else
      up = self.endorsements.where("status='active' AND value=1").count
      down = self.endorsements.where("status='active' AND value=-1").count
    end
    #puts "UP: #{up} DOWN: #{down}"
    if up==0 and down==0
      -800000000
    else
      up-down
    end
  end

  def to_param
    "#{id}-#{name.parameterize_full}"
  end  
  
  def content
    self.name
  end
  
  def setup_revision
    IdeaRevision.create_from_idea(self)
  end

  def author_user
    self.author_users.select("idea_revisions.*, users.*").order("idea_revisions.created_at ASC").first
  end

  def last_author
    self.author_users.select("idea_revisions.*, users.*").order("idea_revisions.created_at DESC").last
  end
  
  def authors
    idea_revisions.count(:group => :user, :order => "count_all desc")
  end
  
  def editors
    idea_revisions.count(:group => :user, :conditions => ["idea_revisions.user_id <> ?", user_id], :order => "count_all desc")
  end

  def endorse(user,request=nil,referral=nil)
    if user
      endorsement = self.endorsements.find_by_user_id(user.id)
      if not endorsement
        endorsement = Endorsement.new(:value => 1, :idea => self, :sub_instance_id => self.sub_instance_id, :user => user,:referral => referral)
        endorsement.ip_address = request.remote_ip if request
        endorsement.save
        endorsement.insert_lowest_at(4)
      elsif endorsement.is_down?
        endorsement.flip_up
        endorsement.save
      end
      if endorsement.is_replaced?
        endorsement.activate!
      end
      return endorsement
    end
  end
  
  def oppose(user,request=nil,referral=nil)
    return false if not user
    endorsement = self.endorsements.find_by_user_id(user.id)
    if not endorsement
      endorsement = Endorsement.new(:value => -1, :idea => self, :sub_instance_id => self.sub_instance_id, :user => user, :referral => referral)
      endorsement.ip_address = request.remote_ip if request
      endorsement.save
      endorsement.insert_lowest_at(4)
    elsif endorsement.is_up?
      endorsement.flip_down
      endorsement.save
    end
    if endorsement.is_replaced?
      endorsement.activate!
    end
    return endorsement
  end  
  
  def is_official_endorsed?
    official_value == 1
  end
  
  def is_official_opposed?
    official_value == -1
  end
  
  def is_rising?
    position_7days_delta > 0
  end  

  def is_falling?
    position_7days_delta < 0
  end
  
  def up_endorsements_count
    Endorsement.where(:idea_id=>self.id, :value=>1).count
  end
  
  def down_endorsements_count
    Endorsement.where(:idea_id=>self.id, :value=>-1).count
  end
  
  def is_controversial?
    return false unless down_endorsements_count > 0 and up_endorsements_count > 0
    (up_endorsements_count/down_endorsements_count) > 0.5 and (up_endorsements_count/down_endorsements_count) < 2
  end
  
  def is_buried?
    status == tr("delisted", "model/idea")
  end
  
  def is_top?
    return false if position == 0
    position < Endorsement.max_position
  end
  
  def is_new?
    return true if not self.attribute_present?("created_at")
    created_at > Time.now-(86400*7) or position_7days == 0    
  end

  def is_published?
    ['published','inactive'].include?(status)
  end
  alias :is_published :is_published?

  def is_finished?
    official_status > 1 or official_status < 0
  end

  def official_status_html_name
    case official_status
    when -2
      "<a class='status failed' href='/ideas/finished_failed'>#{tr("Failed","here")}</a>"
    when 2
      "<a class='status successful' href='/ideas/finished_successful'>#{tr("Successful","here")}</a>"
    when -1
      "<a class='status in_progress' href='/ideas/finished_in_progress'>#{tr("In progress","here")}</a>"
    when 1
      "<a class='status in_progress' href='/ideas/finished_in_progress'>#{tr("In progress","here")}</a>"
    else
      ""
    end
  end

  def is_failed?
    official_status == -2
  end
  
  def is_successful?
    official_status == 2
  end
  
  def is_compromised?
    official_status == -1
  end
  
  def is_intheworks?
    official_status == 1
  end  
  
  def request=(request)
    if request
      self.ip_address = request.remote_ip
      self.user_agent = request.env['HTTP_USER_AGENT']
    else
      self.ip_address = "127.0.0.1"
      self.user_agent = "Import"
    end
  end
  
  def position_7days_delta_percent
    position_7days_delta.to_f/(position+position_7days_delta).to_f
  end
  
  def position_24hr_delta_percent
    position_24hr_delta.to_f/(position+position_24hr_delta).to_f
  end  
  
  def position_30days_delta_percent
    position_30days_delta.to_f/(position+position_30days_delta).to_f
  end  
  
  def value_name 
    if is_failed?
      tr("Idea failed", "model/idea")
    elsif is_successful?
      tr("Idea succesful", "model/idea")
    elsif is_compromised?
      tr("Idea succesful with compromises", "model/idea")
    elsif is_intheworks?
      tr("Idea in the works", "model/idea")
    else
      tr("Idea has not been processed", "model/idea")
    end
  end
  
  def change_status!(change_status)
    if change_status == 0
      reactivate!
    elsif change_status == 2
      successful!
    elsif change_status == -2
      failed!
    elsif change_status == -1
      in_the_works!
    end
  end

  def reactivate!
    self.status_changed_at = Time.now
    self.official_status = 0
    self.status = 'published'
#    self.change = nil
    self.save(:validate => false)
#    deactivate_endorsements  
  end
  
  def failed!
    ActivityIdeaOfficialStatusFailed.create(:idea => self)
    self.status_changed_at = Time.now
    self.official_status = -2
    self.status = 'inactive'
#    self.change = nil
    self.save(:validate => false)
    #deactivate_endorsements
  end
  
  def successful!
    ActivityIdeaOfficialStatusSuccessful.create(:idea => self)
    self.status_changed_at = Time.now
    self.official_status = 2
    self.status = 'inactive'
#    self.change = nil    
    self.save(:validate => false)
    #deactivate_endorsements
  end  

  def in_the_works!
    ActivityIdeaOfficialStatusInTheWorks.create(:idea => self)
    self.status_changed_at = Time.now
    self.official_status = -1
    self.status = 'inactive'
#    self.change = nil
    deactivate_ads_and_refund
    self.save(:validate => false)
    #deactivate_endorsements
  end  
  
  def compromised!
    ActivityIdeaOfficialStatusCompromised.create(:idea => self)
    self.status_changed_at = Time.now
    self.official_status = -1
    self.status = 'inactive'
 #   self.change = nil    
    self.save(:validate => false)
    #deactivate_endorsements
  end

  def deactivate_ads_and_refund
    self.ads.active.each do |ad|
      ad.finish!
      user = ad.user
      refund = ad.cost - ad.spent
      refund = 1 if refund > 0 and refund < 1
      refund = refund.abs.to_i
      if refund
        user.increment!(:capitals_count, refund)
        ActivityCapitalAdRefunded.create(:user => user, :idea => self, :capital => CapitalAdRefunded.create(:recipient => user, :amount => refund))
      end
    end
  end

  def deactivate_endorsements
    for e in endorsements.active
      e.finish!
    end    
  end

  def create_status_update(idea_status_change_log)
    Rails.logger.info("Sending status emails")
    SendStatusEmail.perform_in(1.second,idea_status_change_log.id)
    return ActivityIdeaStatusUpdate.create(idea: self, idea_status_change_log: idea_status_change_log)
  end

  def reactivate!
    self.status = 'published'
    self.change = nil
    self.status_changed_at = Time.now
    self.official_status = 0
    self.save(:validate => false)
    for e in endorsements.active_and_inactive
      e.update_attribute(:status,'active')
      row = 0
      for ue in e.user.endorsements.active.by_position
        row += 1
        ue.update_attribute(:position,row) unless ue.position == row
        e.user.update_attribute(:top_endorsement_id,ue.id) if e.user.top_endorsement_id != ue.id and row == 1
      end      
    end
  end
  
  def intheworks!
    ActivityIdeaOfficialStatusInTheWorks.create(:idea => self, :user => user)
    self.update_attribute(:status_changed_at, Time.now)
    self.update_attribute(:official_status, 1)
  end  
  
  def official_status_name
    return tr("Failed", "status_messages") if official_status == -2
    return tr("In progress", "status_messages") if official_status == -1
    return tr("Unknown", "status_messages") if official_status == 0
    return tr("Published", "status_messages") if official_status == 1
    return tr("Successful", "status_messages") if official_status == 2
  end
  
  def has_change?
    attribute_present?("change_id") and self.status != 'inactive' and change and not change.is_expired?
  end

  def has_tags?
    attribute_present?("cached_issue_list")
  end
  
  def replaced?
    attribute_present?("change_id") and self.status == 'inactive'
  end
  
  def movement_text
    s = ''
    if status == 'buried'
      return tr("delisted", "model/idea").capitalize
    elsif status == 'inactive'
      return tr("inactive", "model/idea").capitalize
    elsif created_at > Time.now-86400
      return tr("new", "model/idea").capitalize
    elsif position_24hr_delta == 0 and position_7days_delta == 0 and position_30days_delta == 0
      return tr("no change", "model/idea").capitalize
    end
    s += '+' if position_24hr_delta > 0
    s += '-' if position_24hr_delta < 0    
    s += tr("no change", "model/idea") if position_24hr_delta == 0
    s += position_24hr_delta.abs.to_s unless position_24hr_delta == 0
    s += ' today'
    s += ', +' if position_7days_delta > 0
    s += ', -' if position_7days_delta < 0    
    s += ', ' + tr("no change", "model/idea") if position_7days_delta == 0
    s += position_7days_delta.abs.to_s unless position_7days_delta == 0
    s += ' this week'
    s += ', and +' if position_30days_delta > 0
    s += ', and -' if position_30days_delta < 0    
    s += ', and ' + tr("no change", "model/idea") if position_30days_delta == 0
    s += position_30days_delta.abs.to_s unless position_30days_delta == 0
    s += ' this month'    
    s
  end
  
  def up_endorser_ids
    @up_endorser_ids ||= endorsements.active_and_inactive.endorsing.collect{|e|e.user_id.to_i}.uniq.compact
  end  
  def down_endorser_ids
    @down_endorser_ids ||= endorsements.active_and_inactive.opposing.collect{|e|e.user_id.to_i}.uniq.compact
  end
  def endorser_ids
    @endoreser_ids ||= endorsements.active_and_inactive.collect{|e|e.user_id.to_i}.uniq.compact
  end
  def all_idea_ids_in_same_tags
    all_idea_ids_in_same_tags ||= begin
      ts = Tagging.find(:all, :conditions => ["tag_id in (?) and taggable_type = 'Idea'",taggings.collect{|t|t.tag_id}.uniq.compact])
      ts.collect{|t|t.taggable_id}.uniq.compact
    end
  end
  
  def undecideds
    return [] unless has_tags? and endorsements_count > 2    
    @undecideds ||= begin
      User.find_by_sql("
      select distinct users.* 
      from users, endorsements
      where endorsements.user_id = users.id
      and endorsements.status = 'active'
      and endorsements.idea_id in (#{all_idea_ids_in_same_tags.join(',')})
      and endorsements.user_id not in (#{endorser_ids.join(',')})
      ")
    end
  end
  
  def related(limit=10)
    Idea.find_by_sql(["SELECT ideas.*, count(*) as num_tags
    from taggings t1, taggings t2, ideas
    where 
    t1.taggable_type = 'Idea' and t1.taggable_id = ?
    and t1.tag_id = t2.tag_id
    and t2.taggable_type = 'Idea' and t2.taggable_id = ideas.id
    and t2.taggable_id <> ?
    and ideas.status = 'published'
    group by ideas.id
    order by num_tags desc, ideas.endorsements_count desc
    limit ?",id,id,limit])  
  end  
  
  def merge_into(p2_id,preserve=false,flip=0) #pass in the id of the idea to merge this one into.
    p2 = Idea.find(p2_id) # p2 is the idea that this one will be merged into
    for e in endorsements
      if not exists = p2.endorsements.find_by_user_id(e.user_id)
        e.idea_id = p2.id
        if flip == 1
          if e.value < 0
            e.value = 1 
          else
            e.value = -1
          end
        end   
        e.save(:validate => false)     
      end
    end
    p2.reload
    size = p2.endorsements.active_and_inactive.length
    up_size = p2.endorsements.active_and_inactive.endorsing.length
    down_size = p2.endorsements.active_and_inactive.opposing.length
    Idea.update(p2.id, endorsements_count: size, up_endorsements_count: up_size, down_endorsements_count: down_size)

    # look for the activities that should be removed entirely
    for a in Activity.find(:all, :conditions => ["idea_id = ? and type in ('ActivityIdeaDebut','ActivityIdeaNew','ActivityIdeaRenamed','ActivityIdeaFlag','ActivityIdeaFlagInappropriate','ActivityIdeaOfficialStatusCompromised','ActivityIdeaOfficialStatusFailed','ActivityIdeaOfficialStatusIntheworks','ActivityIdeaOfficialStatusSuccessful','ActivityIdeaRising1','ActivityIssueIdea1','ActivityIssueIdeaControversial1','ActivityIssueIdeaOfficial1','ActivityIssueIdeaRising1')",self.id])
      a.destroy
    end    
    #loop through the rest of the activities and move them over
    for a in activities
      if flip == 1
        for c in a.comments
          if c.is_opposer?
            c.is_opposer = false
            c.is_endorser = true
            c.save(:validate => false)
          elsif c.is_endorser?
            c.is_opposer = true
            c.is_endorser = false
            c.save(:validate => false)            
          end
        end
        if a.class == ActivityEndorsementNew
          a.update_attribute(:type,'ActivityOppositionNew')
        elsif a.class == ActivityOppositionNew
          a.update_attribute(:type,'ActivityEndorsementNew')
        elsif a.class == ActivityEndorsementDelete
          a.update_attribute(:type,'ActivityOppositionDelete')
        elsif a.class == ActivityOppositionDelete
          a.update_attribute(:type,'ActivityEndorsementDelete')
        elsif a.class == ActivityEndorsementReplaced
          a.update_attribute(:type,'ActivityOppositionReplaced')
        elsif a.class == ActivityOppositionReplaced 
          a.update_attribute(:type,'ActivityEndorsementReplaced')
        elsif a.class == ActivityEndorsementReplacedImplicit
          a.update_attribute(:type,'ActivityOppositionReplacedImplicit')
        elsif a.class == ActivityOppositionReplacedImplicit
          a.update_attribute(:type,'ActivityEndorsementReplacedImplicit')
        elsif a.class == ActivityEndorsementFlipped
          a.update_attribute(:type,'ActivityOppositionFlipped')
        elsif a.class == ActivityOppositionFlipped
          a.update_attribute(:type,'ActivityEndorsementFlipped')
        elsif a.class == ActivityEndorsementFlippedImplicit
          a.update_attribute(:type,'ActivityOppositionFlippedImplicit')
        elsif a.class == ActivityOppositionFlippedImplicit
          a.update_attribute(:type,'ActivityEndorsementFlippedImplicit')
        end
      end
      if preserve and (a.class.to_s[0..26] == 'ActivityIdeaAcquisition' or a.class.to_s[0..25] == 'ActivityCapitalAcquisition')
      else
        a.update_attribute(:idea_id,p2.id)
      end      
    end
    for a in ads
      a.update_attribute(:idea_id,p2.id)
    end    
    for point in points_with_deleted
      point.idea = p2
      if flip == 1
        if point.value > 0
          point.value = -1
        elsif point.value < 0
          point.value = 1
        end 
        # need to flip the helpful/unhelpful counts
        helpful = point.endorser_helpful_count
        unhelpful = point.endorser_unhelpful_count
        point.endorser_helpful_count = point.opposer_helpful_count
        point.endorser_unhelpful_count = point.opposer_unhelpful_count
        point.opposer_helpful_count = helpful
        point.opposer_unhelpful_count = unhelpful        
      end      
      point.save(:validate => false)      
    end
    for point in incoming_points
      if flip == 1
        point.other_idea = nil
      elsif point.other_idea == p2
        point.other_idea = nil
      else
        point.other_idea = p2
      end
      point.save(:validate => false)
    end
    if not preserve # set preserve to true if you want to leave the Change and the original idea in tact, otherwise they will be deleted
      for c in changes_with_deleted
        c.destroy
      end
    end
    # find any issues they may be the top prioritiy for, and remove
    for tag in Tag.find(:all, :conditions => ["top_idea_id = ?",self.id])
      tag.update_attribute(:top_idea_id,nil)
    end
    # zap all old rankings for this idea
    Ranking.connection.execute("delete from rankings where idea_id = #{self.id.to_s}")
    self.reload
    self.destroy if not preserve
    return p2
  end
  
  def flip_into(p2_id,preserve=false) #pass in the id of the idea to flip this one into.  it'll turn up endorsements into down endorsements and vice versa
    merge_into(p2_id,1)
  end  
  
  def show_url
    if self.sub_instance_id
      self.sub_instance.url('ideas/' + to_param)
    else
      Instance.current.homepage_url + 'ideas/' + to_param
    end
  end

  def top_points_url(args = {})
    if self.sub_instance_id
      self.sub_instance.url('ideas/' + to_param + '/top_points')
    else
      Instance.current.homepage_url + 'ideas/top_points' + to_param
    end
  end

  def new_point_url(args = {})
    supp = args.has_key?(:support) ? "?support=#{args[:support]}" : ""
    if self.sub_instance_id
      self.sub_instance.url('ideas/' + to_param + '/points/new' + supp)
    else
      Instance.current.homepage_url + 'ideas/' + to_param
    end
  end
  
  def show_discussion_url
    show_url + '/discussions'
  end

  def show_top_points_url
    show_url + '/top_points'
  end

  def show_endorsers_url
    show_url + '/endorsers'
  end

  def show_opposers_url
    show_url + '/opposers'
  end
  
  # this uses http://is.gd
  def create_short_url
    self.short_url = open('http://is.gd/create.php?longurl=' + show_url, "UserAgent" => "Ruby-ShortLinkCreator").read[/http:\/\/is\.gd\/\w+(?=" onselect)/]
  end

  def latest_idea_process_at
    latest_idea_process_txt = Rails.cache.read("latest_idea_process_at_#{self.id}")
    unless latest_idea_process_txt
      idea_process = IdeaProcess.find_by_idea_id(self, :order=>"created_at DESC, stage_sequence_number DESC")
      if idea_process
        time = idea_process.last_changed_at
      else
        time = Time.now-5.years
      end
      if idea_process.stage_sequence_number == 1 and idea_process.process_discussions.count == 0
        stage_txt = "#{tr("Waiting for discussion","althingi_texts")}"
      else
        stage_txt = "#{idea_process.stage_sequence_number}. #{tr("Discussion stage","althingi_texts")}"
      end
      latest_idea_process_txt = "#{stage_txt}, #{distance_of_time_in_words_to_now(time)}"
      Rails.cache.write("latest_idea_process_at_#{self.id}", latest_idea_process_txt, :expires_in => 30.minutes)
    end
    latest_idea_process_txt.html_safe if latest_idea_process_txt
  end

  def do_abusive!(reason)
    self.user.do_abusive!(notifications,reason)
    self.update_attribute(:flags_count, 0)
  end

  def flag_by_user(user)
    self.increment!(:flags_count)
    default_sub_instance_id = SubInstance.where(:short_name=>"default").first.id
    for r in User.active.admins.where("sub_instance_id = ? OR sub_instance_id = ?",default_sub_instance_id,user.sub_instance_id)
      notifications << NotificationIdeaFlagged.new(:sender => user, :recipient => r)
    end
  end  

  def on_published_entry(new_state = nil, event = nil)
    self.published_at = Time.now
    save(:validate => false) if persisted?
  end
  
  def on_removed_entry(new_state, event)
    [activities, endorsements, points].each do |children|
      children.each do |child|
        child.remove! unless child.status=="removed"
      end
    end
    self.removed_at = Time.now
    for r in idea_revisions
      r.remove!
    end
    deactivate_ads_and_refund
    save(:validate => false)
  end

  def on_unremoved_entry(new_state, event)
    self.removed_at = nil
    save(:validate => false)
  end
  
  def on_buried_entry(new_state, event)
    # should probably send an email notification to the person who submitted it
    # but not doing anything for now.
  end
end
