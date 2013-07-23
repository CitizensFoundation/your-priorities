class IdeaRevision < ActiveRecord::Base
  include ActionView::Helpers::UrlHelper

  class << self
    include HTMLDiff
  end
  scope :published, :conditions => "idea_revisions.status = 'published'"
  scope :by_recently_created, :order => "idea_revisions.created_at desc"  

  belongs_to :idea
  belongs_to :user
  belongs_to :category
    
  has_many :activities
  has_many :notifications, :as => :notifiable, :dependent => :destroy
      
  # this is actually just supposed to be 500, but bumping it to 520 because the javascript counter doesn't include carriage returns in the count, whereas this does.
  validates_length_of :name, :within => 5..225, :too_long => tr("has a maximum of 200 characters", "model/idea"),
                      :too_short => tr("please enter more than 5 characters", "model/idea")

  validates_length_of :description, :within => 12..5050, :too_long => tr("has a maximum of 5000 characters", "model/idea"),
                      :too_short => tr("please enter more than 12 characters", "model/idea")

  validates_length_of :notes, :within => 0..2050, :too_long => tr("has a maximum of 2000 characters", "model/idea"),
                      :too_short => tr("please enter more than -1 characters", "model/idea")

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

  auto_html_for(:notes) do
    html_escape
    simple_format
    image
    youtube(:width => 330, :height => 210)
    vimeo(:width => 330, :height => 180)
    link :target => "_blank", :rel => "nofollow"
  end

  before_save :truncate_user_agent

  def truncate_user_agent
    self.user_agent = self.user_agent[0..149] if self.user_agent # some user agents are longer than 150 chars!
  end

  def on_published_entry(new_state, event)
    self.published_at = Time.now
    #self.auto_html_prepare
    begin
      Timeout::timeout(5) do   #times out after 5 seconds
        if idea.description
          self.description_diff = IdeaRevision.diff(idea.description, self.description).html_safe
        end
        if idea.name
          self.name_diff = IdeaRevision.diff(idea.name,self.name).html_safe
        end
        if idea.notes
          self.notes_diff = IdeaRevision.diff(idea.notes,self.notes).html_safe
        end
      end
    rescue Timeout::Error
    end
    idea.idea_revisions_count += 1
    changed = false
    if idea.idea_revisions_count == 1
      ActivityIdeaNew.create(:user => user, :idea => idea, :idea_revision => self)
    else
      if idea.description != self.description
        changed = true
        ActivityIdeaRevisionDescription.create(:user => user, :idea => idea, :idea_revision => self)
      end
      if idea.notes != self.notes
        changed = true
        ActivityIdeaRevisionNotes.create(:user => user, :idea => idea, :idea_revision => self)
      end
      if idea.name != self.name
        changed = true
        ActivityIdeaRevisionName.create(:user => user, :idea => idea, :idea_revision => self)
      end
      if idea.category != self.category
        changed = true
        ActivityIdeaRevisionCategory.create(:user => user, :idea => idea, :idea_revision => self)
      end
    end
    if changed
      for a in idea.author_users
        if a.id != self.user_id
          notifications << NotificationIdeaRevision.new(:sender => self.user, :recipient => a)
        end
      end
    end

    idea.description = self.description
    idea.notes = self.notes
    idea.idea_revision_id = self.id
    idea.name = self.name
    idea.category = self.category if self.category
    idea.author_sentence = link_to(idea.author_user.login, Rails.application.routes.url_helpers.user_path(idea.author_user))
    idea.author_sentence += ", #{tr("changes","model/revision")} " + idea.editors.collect{|a| link_to(a[0].login,Rails.application.routes.url_helpers.user_path(a[0]))}.to_sentence if idea.editors.size > 0
    idea.published_at = Time.now
    idea.save(:validate => false)
    save(:validate => false)
    user.increment!(:idea_revisions_count)
  end


  def self.recreate_author_sentences
    IdeaRevision.all.each do |revision|
      idea = revision.idea
      idea.author_sentence = link_to(idea.author_user.login, Rails.application.routes.url_helpers.user_path(idea.author_user))
      idea.author_sentence += ", #{tr("changes","model/revision")} " + idea.editors.collect{|a| link_to(a[0].login,Rails.application.routes.url_helpers.user_path(a[0]))}.to_sentence if idea.editors.size > 0
      idea.save(:validate => false)
    end
  end

  def on_archived_entry(new_state, event)
    self.published_at = nil
    save(:validate => false)
  end

  def on_removed_entry(new_state, event)
    Idea.unscoped.find(idea_id).decrement!(:idea_revisions_count)
    user.decrement!(:idea_revisions_count)
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
    s = idea.name
    s += " [#{tr("In support", "model/revision")}]" if is_down?
    s += " [#{tr("Neutral", "model/revision")}]" if is_neutral?
    s += "\r\n" + description
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

  def IdeaRevision.create_from_idea(idea,ip=nil,agent=nil)
    r = IdeaRevision.new
    r.idea = idea
    r.user = idea.user
    r.name = idea.name
    r.category = idea.category
    r.name_diff = idea.name
    r.description = idea.description
    r.description_diff = idea.description
    r.notes = idea.notes
    r.notes_diff = idea.notes
    r.ip_address = ip ? ip : idea.ip_address
    r.user_agent = agent ? agent : idea.user_agent
    r.save(:validate => false)
    r.publish!
  end

  def url
    'http://' + idea.sub_instance.base_url_w_sub_instance + '/ideas/' + idea_id.to_s + '/idea_revisions/' + id.to_s + '?utm_source=ideas_changed&utm_medium=email'
  end

  auto_html_for(:description) do
    html_escape
    youtube :width => 330, :height => 210
    vimeo :width => 330, :height => 180
    link :target => "_blank", :rel => "nofollow"
  end
end
