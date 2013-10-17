class Comment < ActiveRecord::Base

  acts_as_set_sub_instance :table_name=>"comments"

  scope :published, :conditions => "comments.status = 'published'"
  scope :unpublished, :conditions => "comments.status not in ('published','abusive')"

  scope :published_and_abusive, :conditions => "comments.status in ('published','abusive')"
  scope :removed, :conditions => "comments.status = 'removed'"
  scope :flagged, :conditions => "flags_count > 0"
    
  scope :last_three_days, :conditions => "comments.created_at > '#{Time.now-3.days}'"
  scope :by_recently_created, :order => "comments.created_at desc"  
  scope :by_first_created, :order => "comments.created_at asc"  
  scope :by_recently_updated, :order => "comments.updated_at desc"  
  
  belongs_to :user
  belongs_to :activity
  belongs_to :category

  def activity
    Activity.unscoped{ super }
  end

  has_many :notifications, :as => :notifiable, :dependent => :destroy

  attr_accessor :abusive_reason

  validates_presence_of :content

  after_create :on_published_entry

  include Workflow
  workflow_column :status
  workflow do
    state :published do
      event :remove, transitions_to: :removed
      event :abusive, transitions_to: :abusive
    end
    state :removed do
      event :unremove, transitions_to: :published
    end
    state :abusive
  end

  after_create :set_category
  
  def set_category
    if self.activity.idea_id
      self.category_name = self.activity.idea.category.name if self.activity.idea.category
    elsif self.activity.point_id
      self.category_name = self.activity.point.idea.category.name if self.activity.point.idea.category
    else
      self.category_name = tr('No category','search')
    end
    self.save
  end
  
  def on_published_entry(new_state = nil, event = nil)
    self.activity.changed_at = Time.now
    self.activity.comments_count += 1
    self.activity.save(:validate => false)
    self.user.increment!("comments_count")
    for u in activity.followers
      if u.id != self.user_id and not Following.find_by_user_id_and_other_user_id_and_value(u.id,self.user_id,-1)
        notifications << NotificationComment.new(:sender => self.user, :recipient => u)
      end
    end
    if self.activity.comments_count == 1 # this is the first comment, so need to update the discussions_count as appropriate
      if self.activity.has_point? 
        point = Point.find(self.activity.point_id)
        point.update_attribute("discussions_count", point.discussions_count + 1)
      end
      if self.activity.has_idea?
        idea = Idea.find(self.activity.idea_id)
        idea.update_attribute("discussions_count", idea.discussions_count + 1)
        if self.activity.idea.attribute_present?("cached_issue_list")
          for issue in self.activity.idea.issues
            issue.increment!(:discussions_count)
          end
        end        
      end
    end
    self.activity.followings.find_or_create_by_user_id(self.user_id)
    return if self.activity.user_id == self.user_id or (self.activity.class == ActivityBulletinProfileNew and self.activity.other_user_id = self.user_id and self.activity.comments_count < 2) # they are commenting on their own activity
    if exists = ActivityCommentParticipant.find_by_user_id_and_activity_id(self.user_id,self.activity_id)
      exists.increment!("comments_count")
    else
      ActivityCommentParticipant.create(:user => self.user, :activity => self.activity, :comments_count => 1, :is_user_only => true)
    end
  end
  
  def on_removed_entry(new_state, event)
    if self.activity.comments_count == 1
      self.activity.changed_at = self.activity.created_at
    else
      self.activity.changed_at = self.activity.comments.by_recently_created.first.created_at
    end
    self.activity.comments_count -= 1
    self.save(:validate => false)    

    self.user.decrement!("comments_count")
    if self.activity.comments_count == 0
      if self.activity.has_point? and self.activity.point
        self.activity.point.decrement!(:discussions_count)
      end
      if self.activity.has_idea? and self.activity.idea
        self.activity.idea.decrement!(:discussions_count)
        if self.activity.idea.attribute_present?("cached_issue_list")
          for issue in self.activity.idea.issues
            issue.decrement!(:discussions_count)
          end
        end
      end      
    end
    return if self.activity.user_id == self.user_id    
    exists = ActivityCommentParticipant.find_by_user_id_and_activity_id(self.user_id,self.id)
    if exists and exists.comments_count > 1
      exists.decrement!(:comments_count)
    elsif exists
      exists.remove!
    end
    for n in notifications
      n.remove!
    end
  end
  
  def on_abusive_entry(new_state, event)
    self.user.do_abusive!(notifications,self.abusive_reason)
    self.update_attribute(:flags_count, 0)
  end
  
  def request=(request)
    if request
      self.ip_address = request.remote_ip
      self.user_agent = request.env['HTTP_USER_AGENT']
      self.referrer = request.env['HTTP_REFERER']
    end
  end
  
  def parent_name 
    if activity.has_point?
      user.login + ' commented on ' + activity.point.name
    elsif activity.has_idea?
      user.login + ' commented on ' + activity.idea.name
    else
      user.login + ' posted a bulletin'
    end    
  end
  
  def flag_by_user(user)
    self.increment!(:flags_count)
    for r in User.active.admins
      Rails.logger.debug("Processing admin: #{r}")
      notifications << NotificationCommentFlagged.new(:sender => user, :recipient => r)    
      Rails.logger.debug("Notifications: #{notifications}")
    end
  end
  
  def show_url
    if self.sub_instance_id
      Instance.current.homepage_url(self.sub_instance) +  'activities/' + activity_id.to_s + '/comments#' + id.to_s
    else
      Instance.current.homepage_url + 'activities/' + activity_id.to_s + '/comments#' + id.to_s
    end
  end
  
  auto_html_for(:content) do
    html_escape
    simple_format
    image
    youtube(:width => 330, :height => 210)
    vimeo(:width => 330, :height => 180)
    link :target => "_blank", :rel => "nofollow"
  end
  
end
