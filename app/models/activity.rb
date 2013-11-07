class Activity < ActiveRecord::Base
  
  acts_as_set_sub_instance :table_name=>"activities"
  
  scope :active, :conditions => "activities.status = 'active'"
  scope :removed, :conditions => "activities.status = 'removed'", :order => "updated_at desc"
  scope :for_all_users, :conditions => "is_user_only=false"

  scope :discussions, :conditions => "activities.comments_count > 0"
  scope :points, :conditions => "type like 'ActivityPoint%'", :order => "activities.created_at desc"
  scope :capital, :conditions => "type like '%Capital%'"
  scope :interesting, :conditions => "type in ('ActivityIdeaMergeProposal','ActivityIdeaAcquisitionProposal') or comments_count > 0"

  scope :top, :order=>"changed_at DESC", :conditions => "type in ('ActivityPointNew','ActivityIdeaNew','ActivityBulletinNew')"
  scope :top_discussions, :order=>"changed_at DESC", :conditions => "type in ('ActivityBulletinNew')", :limit=>5
  scope :with_20, :limit=> 20

  scope :feed, lambda{|last| {:conditions=>["changed_at < ? ", last], :order=>"changed_at DESC", :limit=>5}}
  scope :last_three_days, :conditions => "activities.changed_at > '#{Time.now-3.days}'"
  scope :last_seven_days, :conditions => "activities.changed_at > '#{Time.now-7.days}'"
  scope :last_thirty_days, :conditions => "activities.changed_at > '#{Time.now-30.days}'"    
  scope :last_24_hours, :conditions => "created_at > '#{Time.now-24.hours}')"  
  
  scope :by_recently_updated, :order => "activities.changed_at desc"  
  scope :by_recently_created, :order => "activities.created_at desc"    

  scope :item_limit, lambda{|limit| {:limit=>limit}}
  scope :by_tag_name, lambda{|tag_name| {:conditions=>["cached_issue_list=?",tag_name]}}

  scope :by_user_id, lambda{|user_id| {:conditions=>["user_id=?",user_id]}}

  belongs_to :user
  belongs_to :sub_instance
  
  belongs_to :other_user, :class_name => "User", :foreign_key => "other_user_id"
  belongs_to :idea
  belongs_to :activity
  belongs_to :tag
  belongs_to :point
  belongs_to :revision
  belongs_to :idea_revision
  belongs_to :capital
  belongs_to :ad
  belongs_to :tag

  belongs_to :idea_status_change_log
  has_many :comments, :order => "comments.created_at asc", :dependent => :destroy
  has_many :published_comments, :class_name => "Comment", :foreign_key => "activity_id", :conditions => "comments.status = 'published'", :order => "comments.created_at asc"
  has_many :commenters, :through => :published_comments, :source => :user, :select => "DISTINCT users.*"
  has_many :activities, :dependent => :destroy
  has_many :notifications, :as => :notifiable, :dependent => :destroy
  has_many :followings, :class_name => "FollowingDiscussion", :foreign_key => "activity_id", :dependent => :destroy
  has_many :followers, :through => :followings, :source => :user, :select => "DISTINCT users.*"

  include Workflow
  workflow_column :status
  workflow do
    state :active do
      event :remove, transitions_to: :removed
    end

    state :removed do
      event :unremove, transitions_to: :active
    end
  end

  before_save :setup_group_id
  before_save :update_changed_at

  def setup_group_id
    if self.idea
      self.group_id = self.idea.group_id
    elsif self.point and self.point.idea
      self.group_id = self.point.idea.group_id
    elsif self.revision and self.revision.point and self.revision.point.idea
      self.group_id = self.revision.point.idea.group_id
    end
  end

  def update_changed_at
    self.changed_at = Time.now unless self.attribute_present?("changed_at")
  end

  def multi_name
    return "test x"
    if self.idea_id
      self.idea.name
    elsif self.point_id
      self.question.name
    else
      "#{self.inspect}"
    end
  end

  def show_multi_url
    return "test m"
    if self.idea_id
      self.idea.show_url
    elsif self.point_id
      self.point.show_url
    else
      "#{self.inspect}"
    end
  end

  def on_removed_entry(new_state, event)
    # go through and mark all the comments as removed
    for comment in published_comments
      comment.remove!
    end
  end

  cattr_reader :per_page
  @@per_page = 25

  def commenters_count
    comments.all.group_by{|x| x.user}
  end  

  def has_idea?
    attribute_present?("idea_id")
  end
  
  def has_activity?
    attribute_present?("activity_id")
  end
  
  def has_user?
    attribute_present?("user_id")
  end    
  
  def has_other_user?
    attribute_present?("other_user_id")
  end  
  
  def has_point?
    attribute_present?("point_id")
  end

  def has_capital?
    attribute_present?("capital_id")
  end  
  
  def has_revision?
    attribute_present?("revision_id")
  end    

  def has_ad?
    attribute_present?("ad_id") and ad
  end
  
  def has_comments?
    comments_count > 0
  end
  
  def first_comment
    comments.published.first
  end
  
  def last_comment
    comments.published.last
  end

  def idea
    Idea.unscoped.find(idea_id) if idea_id
  end

  def point
    Point.unscoped.find(point_id) if point_id
  end

  def activity
    Activity.unscoped.find(activity_id) if activity_id
  end

  def tag
    Tag.unscoped.find(tag_id) if tag_id
  end

  def user
    User.unscoped.find(user_id) if user_id
  end

  def other_user
    User.unscoped.find(other_user_id) if other_user_id
  end
end

class ActivityUserNew < Activity
  def name
    tr("{user_name} joined {instance_name}", "model/activity", :user_name => user.name, :instance_name => Instance.current.name)
  end
end

# Jerry invited Jonathan to join
class ActivityInvitationNew < Activity
  def name
    if user
      tr("{user_name} invited someone to join", "model/activity", :user_name => user.login)
    else
      tr("{user_name} invited someone to join", "model/activity", :user_name => "Someone")
    end
  end
end

# Jonathan accepted Jerry's invitation to join
class ActivityInvitationAccepted < Activity
  def name
    if other_user
      tr("{user_name} accepted an invitation from {other_user_name} to join {instance_name}", "model/activity", :user_name => user.name, :other_user_name => other_user.name, :instance_name => Instance.current.name)
    else
      tr("{user_name} accepted an invitation to join {instance_name}", "model/activity", :user_name => user.name, :instance_name => Instance.current.name)
    end
  end
end

# Jerry recruited Jonathan to White House 2.
class ActivityUserRecruited < Activity

  after_create :add_capital

  def add_capital
    ActivityCapitalUserRecruited.create(:user => user, :other_user => other_user, :capital => CapitalUserRecruited.new(:recipient => user, :amount => 5))
  end

  def name
    tr("{user_name} recruited {other_user_name} to {instance_name}", "model/activity", :user_name => user.name, :other_user_name => other_user.name, :instance_name => Instance.current.name)
  end
end

class ActivityCapitalUserRecruited < Activity
  def name
    tr("{user_name} earned {capital}{currency_short_name} for recruiting {other_user_name} to {instance_name}", "model/activity", :user_name => user.name, :other_user_name => other_user.name, :instance_name => Instance.current.name, :capital => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name)
  end
end

class ActivityPartnerUserRecruited < Activity

  def name
    tr("{user_name} recruited {other_user_name} to {instance_name} through {sub_instance_url}", "model/activity", :user_name => user.name, :other_user_name => other_user.name, :instance_name => Instance.current.name, :sub_instance_url => sub_instance.short_name + '.' + Instance.current.base_url)
  end

end

class ActivityCapitalPartnerUserRecruited < Activity
  def name
    tr("{user_name} earned {capital}{currency_short_name} for recruiting {other_user_name} to {instance_name} through {sub_instance_url}", "model/activity", :user_name => user.name, :other_user_name => other_user.name, :instance_name => Instance.current.name, :capital => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name, :sub_instance_url => sub_instance.short_name + '.' + Instance.current.base_url)
  end
end

class ActivityIdeaDebut < Activity

  def name
    if attribute_present?("position")
      tr("{idea_name} debuted on the charts at {position}", "model/activity", :idea_name => idea.name, :position => position)
    else
      tr("{idea_name} debuted on the charts", "model/activity", :idea_name => idea.name)
    end
  end

end

class ActivityUserRankingDebut < Activity

  def name
    if attribute_present?("position")
      tr("{user_name} debuted on the most influential chart at {position}", "model/activity", :user_name => user.name, :position => position)
    else
      tr("{user_name} debuted on the most influential chart", "model/activity", :user_name => user.name)
    end
  end

end

class ActivityEndorsementNew < Activity

  def name
    if has_ad?
      if attribute_present?("position")
        tr("{user_name} endorsed {idea_name} at #{IDEA_TOKEN} {position} due to {ad_user} ad", "model/activity", :user_name => user.name, :idea_name => idea.name, :position => position, :ad_user => ad.user.name.possessive)
      else
        tr("{user_name} endorsed {idea_name} due to {ad_user} ad", "model/activity", :user_name => user.name, :idea_name => idea.name, :ad_user => ad.user.name.possessive)
      end
    else
      if attribute_present?("position")
        tr("{user_name} endorsed {idea_name} at #{IDEA_TOKEN} {position}", "model/activity", :user_name => user.name, :idea_name => idea.name, :position => position)
      else
        tr("{user_name} endorsed {idea_name}", "model/activity", :user_name => user.name, :idea_name => idea.name)
      end
    end
  end

end

class ActivityEndorsementDelete < Activity
  def name
    tr("{user_name} no longer endorses {idea_name}", "model/activity", :user_name => user.name, :idea_name => idea.name)
  end
end

class ActivityOppositionNew < Activity

  def name
    if has_ad?
      if attribute_present?("position")
        tr("{user_name} opposed {idea_name} at #{IDEA_TOKEN} {position} due to {ad_user} ad", "model/activity", :user_name => user.name, :idea_name => idea.name, :position => position, :ad_user => ad.user.name.possessive)
      else
        tr("{user_name} opposed {idea_name} due to {ad_user} ad", "model/activity", :user_name => user.name, :idea_name => idea.name, :ad_user => ad.user.name.possessive)
      end
    else
      if attribute_present?("position")
        tr("{user_name} opposed {idea_name} at #{IDEA_TOKEN} {position}", "model/activity", :user_name => user.name, :idea_name => idea.name, :position => position)
      else
        tr("{user_name} opposed {idea_name}", "model/activity", :user_name => user.name, :idea_name => idea.name)
      end
    end
  end

end

class ActivityOppositionDelete < Activity
  def name
    tr("{user_name} no longer opposes {idea_name}", "model/activity", :user_name => user.name, :idea_name => idea.name)
  end
end

class ActivityEndorsementReplaced < Activity
  def name
    tr("{user_name} endorsed {new_idea_name} instead of {idea_name}", "model/activity", :user_name => user.name, :idea_name => idea.name, :new_idea_name => change.new_idea.name)
  end
end

class ActivityEndorsementReplacedImplicit < Activity
  def name
    tr("{user_name} is now endorsing {new_idea_name} because {idea_name} was acquired", "model/activity", :user_name => user.name, :idea_name => idea.name, :new_idea_name => change.new_idea.name)
  end
end

class ActivityEndorsementFlipped < Activity
  def name
    tr("{user_name} endorsed {new_idea_name} instead of opposing {idea_name}", "model/activity", :user_name => user.name, :idea_name => idea.name, :new_idea_name => change.new_idea.name)
  end
end

class ActivityEndorsementFlippedImplicit < Activity
  def name
    tr("{user_name} is now endorsing {new_idea_name} because it acquired the opposers of {idea_name}", "model/activity", :user_name => user.name, :idea_name => idea.name, :new_idea_name => change.new_idea.name)
  end
end

class ActivityOppositionReplaced < Activity
  def name
    tr("{user_name} opposed {new_idea_name} instead of {idea_name}", "model/activity", :user_name => user.name, :idea_name => idea.name, :new_idea_name => change.new_idea.name)
  end
end

class ActivityOppositionReplacedImplicit < Activity
  def name
    tr("{user_name} is now opposing {new_idea_name} because {idea_name} was acquired", "model/activity", :user_name => user.name, :idea_name => idea.name, :new_idea_name => change.new_idea.name)
  end
end

class ActivityOppositionFlipped < Activity
  def name
    tr("{user_name} opposed {new_idea_name} instead of opposing {idea_name}", "model/activity", :user_name => user.name, :idea_name => idea.name, :new_idea_name => change.new_idea.name)
  end
end

class ActivityOppositionFlippedImplicit < Activity
  def name
    tr("{user_name} is now endorsing {new_idea_name} because it acquired the opposers of {idea_name}", "model/activity", :user_name => user.name, :idea_name => idea.name, :new_idea_name => change.new_idea.name)
  end
end

class ActivityPartnerNew < Activity
  def name
    tr("{sub_instance_name} is a new sub_instance", "model/activity", :sub_instance_name => sub_instance.name)
  end
end

class ActivityIdeaNew < Activity
  def name
    tr("{user_name} first suggested {idea_name}", "model/activity", :user_name => user.name, :idea_name => idea.name)
  end
end

# [user name] flagged [idea name] as inappropriate.
class ActivityIdeaFlagInappropriate < Activity

  def name
    tr("{user_name} flagged {idea_name} for review", "model/activity", :user_name => user.name, :idea_name => idea.name)
  end

  validates_uniqueness_of :user_id, :scope => [:idea_id], :message => "You've already flagged this."

end

class ActivityIdeaFlag < Activity

  def name
    tr("{user_name} flagged {idea_name} for review", "model/activity", :user_name => user.name, :idea_name => idea.name)
  end

  after_create :notify_admin

  def notify_admin
    for r in User.active.admins
      idea.notifications << NotificationIdeaFlagged.new(:sender => user, :recipient => r) if r.id != user.id
    end
  end

end

# [user name] buried [idea name].
class ActivityIdeaBury < Activity
  def name
    tr("{user_name} buried {idea_name}. It's probably obvious why.", "model/activity", :user_name => user.name, :idea_name => idea.name)
  end
end

# identifies that a person is participating in a discussion about another activity
# is_user_only!  it's not meant to be shown on the idea page, just on the user page
# and it's only supposed to be invoked once, when they first start discussing an activity
# but the updated_at should be updated on subsequent postings in the discussion
class ActivityCommentParticipant < Activity

  def name
    tr("{user_name} left {count} comments on {discussion_name}", "model/activity", :user_name => user.name ? user.name : "Unknown user", :count => comments_count, :discussion_name => activity.name ? activity.name : "Unknown activity")
  end

end

class ActivityDiscussionFollowingNew < Activity
  def name
    tr("{user_name} is following the discussion on {discussion_name}", "model/activity", :user_name => user.name, :discussion_name => activity.name)
  end
end

class ActivityDiscussionFollowingDelete < Activity
  def name
    tr("{user_name} stopped following the discussion on {discussion_name}", "model/activity", :user_name => user.name, :discussion_name => activity.name)
  end
end

class ActivityIdeaCommentNew < Activity
  def name
    tr("{user_name} left a comment on {idea_name}", "model/activity", :user_name => user.name, :idea_name => idea.name)
  end
end

class ActivityBulletinProfileNew < Activity

  def send_notification
    notifications << NotificationProfileBulletin.new(:sender => self.other_user, :recipient => self.user)
  end

  def name
    tr("{user_name} posted a bulletin to {other_user_name} profile", "model/activity", :user_name => other_user.name, :other_user_name => user.name.possessive)
  end

end

class ActivityBulletinProfileAuthor < Activity

  def name
    tr("{user_name} posted a bulletin to {other_user_name} profile", "model/activity", :user_name => user.name, :other_user_name => other_user.name.possessive)
  end

end

class ActivityBulletinNew < Activity

  def name
    if point
      tr("{user_name} posted a bulletin to {discussion_name}", "model/activity", :user_name => user.name, :discussion_name => point.name)
    elsif idea
      tr("{user_name} posted a bulletin to {discussion_name}", "model/activity", :user_name => user.name, :discussion_name => idea.name)
    else
      tr("{user_name} posted a bulletin", "model/activity", :user_name => user.name)
    end
  end

end

class ActivityIdea1 < Activity
  def name
    tr("{idea_name} is {user_name} new #1 idea", "model/activity", :user_name => user.name.possessive, :idea_name => idea.name)
  end
end

class ActivityIdea1Opposed < Activity
  def name
    tr("Opposing {idea_name} is {user_name} new #1 idea", "model/activity", :user_name => user.name.possessive, :idea_name => idea.name)
  end
end

class ActivityIdeaRising1 < Activity
  def name
    tr("{idea_name} is the fastest rising idea", "model/activity", :idea_name => idea.name)
  end
end

class ActivityIssueIdea1 < Activity
  def name
    tr("{idea_name} is the new #1 idea in {tag_name}", "model/activity", :idea_name => idea.name, :tag_name => tr(tag.title,"model/category"))
  end
end

class ActivityIssueIdeaControversial1 < Activity
  def name
    tr("{idea_name} is the most controversial idea in {tag_name}", "model/activity", :idea_name => idea.name, :tag_name => tr(tag.title,"model/category"))
  end
end

class ActivityIssueIdeaRising1 < Activity
  def name
    tr("{idea_name} is the fastest rising idea in {tag_name}", "model/activity", :idea_name => idea.name, :tag_name => tr(tag.title,"model/category"))
  end
end

class ActivityIssueIdeaOfficial1 < Activity
  def name
    tr("{idea_name} is the new #1 idea on {official_user_name} {tag_name} agenda", "model/activity", :idea_name => idea.name, :tag_name => tr(tag.title,"model/category"), :official_user_name => Instance.current.official_user.name.possessive)
  end
end

class ActivityIdeaMergeProposal < Activity
  def name
    tr("{user_name} proposed {new_idea_name} acquire {idea_name}", "model/activity", :user_name => user.name, :idea_name => idea.name, :new_idea_name => change.new_idea.name)
  end
end

class ActivityIdeaRenamed < Activity
  def name
    tr("{user_name} renamed {idea_name}", "model/activity", :user_name => user.name, :idea_name => idea.name)
  end
end

class ActivityPointNew < Activity

  def name
    tr("{user_name} added {point_name} to {idea_name}", "model/activity", :user_name => user.name, :point_name => point.name, :idea_name => idea.name)
  end

end

class ActivityPointDeleted < Activity
  def name
    tr("{user_name} deleted {point_name}", "model/activity", :user_name => user.name, :point_name => point.name)
  end
end


class ActivityIdeaRevisionDescription < Activity
  def name
    tr("{user_name} revised {idea_name}", "model/activity", :user_name => user.name, :idea_name => idea.name)
  end
end

class ActivityIdeaRevisionNotes < Activity
  def name
    tr("{user_name} revised {idea_name}", "model/activity", :user_name => user.name, :idea_name => idea.name)
  end
end

class ActivityIdeaRevisionName < Activity
  def name
    tr("{user_name} changed the idea's title to {idea_name}", "model/activity", :user_name => user.name, :idea_name => idea.name)
  end
end

class ActivityIdeaRevisionCategory < Activity
  def name
    tr("{user_name} changed the idea's category to {category_name}", "model/activity", :user_name => user.name, :category_name => idea.category.name)
  end
end

class ActivityPointRevisionContent < Activity
  def name
    tr("{user_name} revised {point_name}", "model/activity", :user_name => user.name, :point_name => point.name)
  end
end

class ActivityPointRevisionName < Activity
  def name
    tr("{user_name} changed the point's title to {point_name}", "model/activity", :user_name => user.name, :point_name => point.name)
  end
end

class ActivityPointRevisionOtherIdea < Activity
  def name
    if revision.has_other_idea?
      tr("{user_name} linked {point_name} to {idea_name}", "model/activity", :user_name => user.name, :point_name => point.name, :idea_name => revision.other_idea.name)
    else
      tr("{user_name} removed the idea link from {point_name}", "model/activity", :user_name => user.name, :point_name => point.name)
    end
  end
end

class ActivityPointRevisionWebsite < Activity
  def name
    if revision.has_website?
      tr("{user_name} revised the source link for {point_name}", "model/activity", :user_name => user.name, :point_name => point.name)
    else
      tr("{user_name} removed the source link from {point_name}", "model/activity", :user_name => user.name, :point_name => point.name)
    end
  end
end

class ActivityPointRevisionSupportive < Activity
  def name
    tr("{user_name} revised {point_name} to indicate it's supportive of {idea_name}", "model/activity", :user_name => user.name, :point_name => point.name, :idea_name => idea.name)
  end
end

class ActivityPointRevisionNeutral < Activity
  def name
    tr("{user_name} revised {point_name} to indicate it's neutral on {idea_name}", "model/activity", :user_name => user.name, :point_name => point.name, :idea_name => idea.name)
  end
end

class ActivityPointRevisionOpposition < Activity
  def name
    tr("{user_name} revised {point_name} to indicate it's opposed to {idea_name}", "model/activity", :user_name => user.name, :point_name => point.name, :idea_name => idea.name)
  end
end

class ActivityPointHelpful < Activity
  def name
    tr("{user_name} marked {point_name} helpful", "model/activity", :user_name => user.name, :point_name => point.name)
  end
end

class ActivityPointUnhelpful < Activity
  def name
    tr("{user_name} marked {point_name} unhelpful", "model/activity", :user_name => user.name, :point_name => point.name)
  end
end

class ActivityPointHelpfulDelete < Activity
  def name
    tr("{user_name} no longer finds {point_name} helpful", "model/activity", :user_name => user.name, :point_name => point.name)
  end
end

class ActivityPointUnhelpfulDelete < Activity
  def name
    tr("{user_name} no longer finds {point_name} unhelpful", "model/activity", :user_name => user.name, :point_name => point.name)
  end
end

class ActivityUserPictureNew < Activity
  def name
    tr("{user_name} changed their profile picture", "model/activity", :user_name => user.name)
  end
end

class ActivityPartnerPictureNew < Activity
  def name
    tr("{sub_instance_name} has a new logo", "model/activity", :user_name => user.name, :sub_instance_name => sub_instance.name)
  end
end

class ActivityCapitalPointHelpfulEveryone < Activity
  def name
    if capital.amount > 0
      tr("{user_name} earned {capital}{currency_short_name} because both endorsers and opposers found {point_name} helpful", "model/activity", :user_name => user.name, :point_name => point.name, :capital => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name)
    elsif capital.amount < 0
      tr("{user_name} lost {capital}{currency_short_name} because both endorsers and opposers found {point_name} unhelpful", "model/activity", :user_name => user.name, :point_name => point.name, :capital => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name)
    end
  end
end

class ActivityCapitalPointHelpfulEndorsers < Activity
  def name
    if capital.amount > 0
      if capital.is_undo?
        tr("{user_name} earned {capital}{currency_short_name} because endorsers didn't find {point_name} unhelpful anymore", "model/activity", :user_name => user.name, :point_name => point.name, :capital => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name)
      else
        tr("{user_name} earned {capital}{currency_short_name} because endorsers found {point_name} helpful", "model/activity", :user_name => user.name, :point_name => point.name, :capital => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name)
      end
    elsif capital.amount < 0
      if capital.is_undo?
        tr("{user_name} lost {capital}{currency_short_name} because endorsers didn't found {point_name} helpful anymore", "model/activity", :user_name => user.name, :point_name => point.name, :capital => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name)
      else
        tr("{user_name} lost {capital}{currency_short_name} because endorsers found {point_name} unhelpful", "model/activity", :user_name => user.name, :point_name => point.name, :capital => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name)
      end
    end
  end
end

class ActivityCapitalPointHelpfulOpposers < Activity
  def name
    if capital.amount > 0
      if capital.is_undo?
        tr("{user_name} earned {capital}{currency_short_name} because opposers didn't find {point_name} unhelpful anymore", "model/activity", :user_name => user.name, :point_name => point.name, :capital => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name)
      else
        tr("{user_name} earned {capital}{currency_short_name} because opposers found {point_name} helpful", "model/activity", :user_name => user.name, :point_name => point.name, :capital => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name)
      end
    elsif capital.amount < 0
      if capital.is_undo?
        tr("{user_name} lost {capital}{currency_short_name} because opposers didn't find {point_name} helpful anymore", "model/activity", :user_name => user.name, :point_name => point.name, :capital => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name)
      else
        tr("{user_name} lost {capital}{currency_short_name} because opposers found {point_name} unhelpful", "model/activity", :user_name => user.name, :point_name => point.name, :capital => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name)
      end
    end
  end
end

class ActivityCapitalPointHelpfulUndeclareds < Activity
  def name
    if capital.amount > 0
      if capital.is_undo?
        tr("{user_name} earned {capital}{currency_short_name} because undeclareds didn't find {point_name} unhelpful anymore", "model/activity", :user_name => user.name, :point_name => point.name, :capital => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name)
      else
        tr("{user_name} earned {capital}{currency_short_name} because undeclareds found {point_name} helpful", "model/activity", :user_name => user.name, :point_name => point.name, :capital => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name)
      end
    elsif capital.amount < 0
      if capital.is_undo?
        tr("{user_name} lost {capital}{currency_short_name} because undeclareds didn't find {point_name} helpful anymore", "model/activity", :user_name => user.name, :point_name => point.name, :capital => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name)

      else
        tr("{user_name} lost {capital}{currency_short_name} because undeclareds found {point_name} unhelpful", "model/activity", :user_name => user.name, :point_name => point.name, :capital => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name)
      end
    end
  end
end

class ActivityCapitalPointHelpfulDeleted < Activity
  def name
    tr("{user_name} lost {capital}{currency_short_name} for deleting {point_name} because people found it helpful", "model/activity", :user_name => user.name, :point_name => point.name, :capital => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name)
  end
end

# this is currently turned off, but the idea was to give capital for followers on twitter.
class ActivityCapitalTwitterFollowers < Activity
  def name
    if capital.amount > 0
      tr("{user_name} earned {count}{currency_short_name} for {count} new followers on Twitter", "model/activity", :user_name => user.name, :count => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name)
    elsif capital.amount < 0
      tr("{user_name} lost {count}{currency_short_name} for {count} less followers on Twitter", "model/activity", :user_name => user.name, :count => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name)
    end
  end
end

class ActivityCapitalFollowers < Activity
  def name
    if capital.amount > 0
      tr("{user_name} earned {count}{currency_short_name} for {count} new followers", "model/activity", :user_name => user.name, :count => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name)
    elsif capital.amount < 0
      tr("{user_name} lost {count}{currency_short_name} for {count} less followers", "model/activity", :user_name => user.name, :count => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name)
    end
  end
end

class ActivityCapitalInstanceNew < Activity
  def name
    tr("{user_name} earned {capital}{currency_short_name} for founding this nation", "model/activity", :user_name => user.name, :capital => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name)
  end
end

class ActivityCapitalAdRefunded < Activity
  def name
    tr("{user_name} was refunded {capital}{currency_short_name} for an ad for idea {idea_name} because the idea is now in progress", "model/activity", :user_name => user.name, :capital => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name, :idea_name => idea.name)
  end
end

class ActivityFollowingNew < Activity
  def name
    tr("{user_name} is now following {other_user_name}", "model/activity", :user_name => user.name, :other_user_name => other_user.name)
  end
end

class ActivityFollowingDelete < Activity
  def name
    tr("{user_name} stopped following {other_user_name}", "model/activity", :user_name => user.name, :other_user_name => other_user.name)
  end
end

class ActivityCapitalIgnorers < Activity
  def name
    if capital.amount > 0
      tr("{user_name} earned {count}{currency_short_name} because {count} people stopped ignoring", "model/activity", :user_name => user.name, :count => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name)
    elsif capital.amount < 0
      tr("{user_name} lost {count}{currency_short_name} because {count} people are ignoring", "model/activity", :user_name => user.name, :count => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name)
    end
  end
end

class ActivityCapitalInactive < Activity
  def name
    tr("{user_name} lost {capital}{currency_short_name} for not logging in recently", "model/activity", :user_name => user.name, :capital => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name)
  end
end

class ActivityIgnoringNew < Activity
  def name
    tr("{user_name} is ignoring someone", "model/activity", :user_name => user.name, :other_user_name => other_user.name)
  end
end

class ActivityIgnoringDelete < Activity
  def name
    tr("{user_name} stopped ignoring someone", "model/activity", :user_name => user.name, :other_user_name => other_user.name)
  end
end

class ActivityOfficialLetter < Activity
  def name
    tr("{user_name} Activity Official Letter", "model/activity", :user_name => user.name, :official_user_name => Instance.current.official_user.name)
  end
end

class ActivityCapitalOfficialLetter < Activity
  def name
    tr("{user_name} earned {capital}{currency_short_name} for sending their agenda to {official_user_name}", "model/activity", :user_name => user.name, :capital => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name, :official_user_name => Instance.current.official_user.name)
  end
end

class ActivityCapitalAdNew < Activity
  def name
    tr("{user_name} spent {capital}{currency_short_name} on an ad for {idea_name}", "model/activity", :user_name => user.name, :capital => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name, :idea_name => idea.name)
  end
end

class ActivityCapitalAcquisitionProposal < Activity
  def name
    tr("{user_name} spent {capital}{currency_short_name} on a proposal for {new_idea_name} to acquire {idea_name}", "model/activity", :user_name => user.name, :capital => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name, :idea_name => idea.name, :new_idea_name => change.new_idea.name)
  end
end

class ActivityIdeaAcquisitionProposalNo < Activity
  def name
    tr("{user_name} voted against {new_idea_name} acquiring {idea_name}", "model/activity", :user_name => user.name, :idea_name => idea.name, :new_idea_name => change.new_idea.name)
  end
end

class ActivityIdeaAcquisitionProposalApproved < Activity
  def name
    tr("{new_idea_name} acquired {idea_name}", "model/activity", :idea_name => idea.name, :new_idea_name => change.new_idea.name)
  end
end

class ActivityIdeaAcquisitionProposalDeclined < Activity
  def name
    tr("{new_idea_name} failed to acquire {idea_name}", "model/activity", :idea_name => idea.name, :new_idea_name => change.new_idea.name)
  end
end

class ActivityIdeaAcquisitionProposalDeleted < Activity
  def name
    tr("{user_name} decided not to hold a vote on {new_idea_name} acquiring {idea_name}", "model/activity", :user_name => user.name, :idea_name => idea.name, :new_idea_name => change.new_idea.name)
  end
end

class ActivityCapitalAcquisitionProposalDeleted < Activity
  def name
    tr("{user_name} was refunded {capital}{currency_short_name} because no vote will be held on {new_idea_name} acquiring {idea_name}", "model/activity", :user_name => user.name, :capital => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name, :idea_name => idea.name, :new_idea_name => change.new_idea.name)
  end
end

class ActivityCapitalAcquisitionProposalApproved < Activity
  def name
    tr("{user_name} earned {capital}{currency_short_name} because {new_idea_name} successfully acquired {idea_name}", "model/activity", :user_name => user.name, :capital => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name, :idea_name => idea.name, :new_idea_name => change.new_idea.name)
  end
end

class ActivityIdeaOfficialStatusFailed < Activity
  def name
    tr("{idea_name} failed", "model/activity", :idea_name => idea.name)
  end
end

class ActivityIdeaOfficialStatusCompromised < Activity
  def name
    tr("{idea_name} was completed with a compromise", "model/activity", :idea_name => idea.name)
  end
end

class ActivityIdeaOfficialStatusInTheWorks < Activity
  def name
    tr("{idea_name} is in progress", "model/activity", :idea_name => idea.name)
  end
end

class ActivityIdeaOfficialStatusSuccessful < Activity
  def name
    tr("{idea_name} was completed successfully", "model/activity", :idea_name => idea.name)
  end
end

class ActivityIdeaStatusUpdate < Activity
  def name
    tr("{idea_name}'s status was updated", "model/activity", idea_name: idea.name)
  end
end

class ActivityCapitalWarning < Activity
  def name
    tr("{user_name} lost {capital}{currency_short_name} for violating the site rules", "model/activity", :user_name => user.name, :capital => capital.amount.abs, :currency_short_name => Instance.current.currency_short_name)
  end
end

class ActivityUserProbation < Activity
  def name
    tr("{user_name} is on probation for a week due to repeated violations of the site rules", "model/activity", :user_name => user.name)
  end
end

class ActivityContentRemoval < Activity
  def name
    tr("{custom_text}", "model/activity", :custom_text=> custom_text)
  end
end
