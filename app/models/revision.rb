class Revision < ActiveRecord::Base
  include ActionView::Helpers::UrlHelper

  class << self
    include HTMLDiff
  end
  scope :published, :conditions => "revisions.status = 'published'"
  scope :by_recently_created, :order => "revisions.created_at desc"  

  belongs_to :point  
  belongs_to :user
  belongs_to :other_idea, :class_name => "Idea"
    
  has_many :activities
  has_many :notifications, :as => :notifiable, :dependent => :destroy
      
  # this is actually just supposed to be 500, but bumping it to 520 because the javascript counter doesn't include carriage returns in the count, whereas this does.
  validates_length_of :content, :maximum => 520, :allow_blank => true, :allow_nil => true, :too_long => tr("has a maximum of 500 characters", "model/revision")

  include Workflow
  workflow_column :status
  workflow do
    state :draft do
      event :publish, transitions_to: :published
    end
    state :archived do
      event :publish, transitions_to: :published
      event :remove, transitions_to: :removed
    end
    state :published do
      event :archive, transitions_to: :archived
      event :remove, transitions_to: :removed
    end
    state :removed do
      event :unremove, transitions_to: :published, meta: { validates_presence_of: [:published_at] }
      event :unremove, transitions_to: :archived
    end
  end

  before_save :truncate_user_agent
  
  def truncate_user_agent
    self.user_agent = self.user_agent[0..149] if self.user_agent # some user agents are longer than 150 chars!
  end
  
  def on_published_entry(new_state, event)
    self.published_at = Time.now
#    self.auto_html_prepare
    begin
      Timeout::timeout(5) do   #times out after 5 seconds
        self.content_diff = Revision.diff(point.content,self.content).html_safe
      end
    rescue Timeout::Error
    end    
    point.revisions_count += 1    
    changed = false
    if point.revisions_count == 1
      ActivityPointNew.create(:user => user, :idea => point.idea, :point => point, :revision => self)
    else
      if point.content != self.content # they changed content
        changed = true
        ActivityPointRevisionContent.create(:user => user, :idea => point.idea, :point => point, :revision => self)
      end
      if point.website != self.website
        changed = true
        ActivityPointRevisionWebsite.create(:user => user, :idea => point.idea, :point => point, :revision => self)
      end
      if point.name != self.name
        changed = true
        ActivityPointRevisionName.create(:user => user, :idea => point.idea, :point => point, :revision => self)
      end
      if point.other_idea_id != self.other_idea_id
        changed = true
        ActivityPointRevisionOtherIdea.create(:user => user, :idea => point.idea, :point => point, :revision => self)
      end
      if point.value != self.value
        changed = true
        if self.is_up?
          ActivityPointRevisionSupportive.create(:user => user, :idea => point.idea, :point => point, :revision => self)
        elsif self.is_neutral?
          ActivityPointRevisionNeutral.create(:user => user, :idea => point.idea, :point => point, :revision => self)
        elsif self.is_down?
          ActivityPointRevisionOpposition.create(:user => user, :idea => point.idea, :point => point, :revision => self)
        end
      end      
    end    
    if changed
      for a in point.author_users
        if a.id != self.user_id
          notifications << NotificationPointRevision.new(:sender => self.user, :recipient => a)    
        end
      end
    end    
    point.content = self.content
    point.website = self.website
    point.revision_id = self.id
    point.value = self.value
    point.name = self.name
    point.other_idea = self.other_idea
    point.author_sentence = link_to(point.author_user.login, Rails.application.routes.url_helpers.user_path(point.author_user))
    point.author_sentence += ", #{tr("changes","model/revision")} " + point.editors.collect{|a| link_to(a[0].login,Rails.application.routes.url_helpers.user_path(a[0]))}.to_sentence if point.editors.size > 0
    point.published_at = Time.now
    point.save(:validate => false)
    save(:validate => false)
    user.increment!(:point_revisions_count)    
  end

  def self.recreate_author_sentences
    Revision.all.each do |revision|
      point = revision.point
      point.author_sentence = link_to(point.author_user.login, Rails.application.routes.url_helpers.user_path(point.author_user))
      point.author_sentence += ", changes " + point.editors.collect{|a| link_to(a[0].login,Rails.application.routes.url_helpers.user_path(a[0]))}.to_sentence if point.editors.size > 0
      point.save(:validate => false)
    end
  end

  def recreate_author_sentences(point)
    revision = self
    point.author_sentence = link_to(point.user.login, Rails.application.routes.url_helpers.user_path(point.user))
    point.save(:validate => false)
  end

  def on_archived_entry(new_state, event)
    self.published_at = nil
    save(:validate => false)
  end
  
  def on_removed_entry(new_state, event)
    point.decrement!(:revisions_count)
    user.decrement!(:point_revisions_count)    
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
  
  def text
    s = point.name
    s += " [#{tr("In support", "model/revision")}]" if is_down?
    s += " [#{tr("Neutral", "model/revision")}]" if is_neutral?    
    s += "\r\n#{tr("In support of", "model/revision")} " + point.other_idea.name if point.has_other_idea?
    s += "\r\n" + content
    s += "\r\n#{tr("Originated at", "model/revision")}: " + website_link if has_website?
    return s
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
  
  def request=(request)
    if request
      self.ip_address = request.remote_ip
      self.user_agent = request.env['HTTP_USER_AGENT']
    else
      self.ip_address = "127.0.0.1"
      self.user_agent = "Import"
    end
  end
  
  def Revision.create_from_point(point,ip=nil,agent=nil)
    r = Revision.new
    r.point = point
    r.user = point.user
    r.value = point.value
    r.name = point.name
    r.content = point.content
    r.content_diff = point.content
    r.ip_address = ip ? ip : point.ip_address
    r.user_agent = agent ? agent : point.user_agent
    r.website = point.website    
    r.save(:validate => false)
    r.publish!
  end
  
  def url
    'http://' + Instance.current.base_url_w_sub_instance + '/points/' + point_id.to_s + '/revisions/' + id.to_s + '?utm_source=points_changed&utm_medium=email'
  end  
  
  auto_html_for(:content) do
    html_escape
    youtube :width => 330, :height => 210
    vimeo :width => 330, :height => 180
    link :target => "_blank", :rel => "nofollow"
  end  
end
